
<%@ page import="org.mskcc.cbio.portal.servlet.QueryBuilder" %>

<% request.setAttribute(QueryBuilder.HTML_TITLE, "Genomic alterations across cancers��"); %>
<jsp:include page="WEB-INF/jsp/global/header.jsp" flush="true" />
<div id="main">
</div>
    </td>
  </tr>
  <tr>
    <td colspan="3">
	<jsp:include page="WEB-INF/jsp/global/footer.jsp" flush="true" />
    </td>
  </tr>
</table>
</center>
</div>
</form>
<jsp:include page="WEB-INF/jsp/global/xdebug.jsp" flush="true" />

<script type="text/template" id="form-template">
    <div>
        <label><b>Cancer studies:</b></label></br>
        <div id="cancer-study-selection"></div>
    </div>
    <br/>
    <div>
        <label><b>Data type:</b></label>
        <select id="data-type">
            <option selected="selected" value="missense">Missense Mutations</option>
            <option value="truncating">Truncating Mutations</option>
            <option value="cna">Copy Number Alteration</option>
        </select>
    </div>
    <br/>
    <div>
        <label><b>Threshold of number samples:</b></label>
        <input type='text' id='threshold-number-samples' value="10">
    </div>
    <br/>
    <div>
        <button type="submit">Submit</button>
    </div>
</script>
    
<script type="text/template" id="cancer-study-template">
    &nbsp;&nbsp;<input type="checkbox" name="{{ id }}" value="{{ id }}">{{ name }}
</script>

<script type="text/template" id="datatables-template">
    <table cellpadding="0" cellspacing="0" border="0" class="display" id="{{ table_id }}">
    </table>
</script>

<style type="text/css" title="currentStyle"> 
        @import "css/data_table_jui.css";
        @import "css/data_table_ColVis.css";
        .ColVis {
                float: left;
                margin-bottom: 0
        }
        .dataTables_length {
                width: auto;
                float: right;
        }
        .dataTables_info {
                clear: none;
                width: auto;
                float: right;
        }
        .div.datatable-paging {
                width: auto;
                float: right;
        }
</style>

<script type="text/javascript">
// This is for the moustache-like templates
// prevents collisions with JSP tags
_.templateSettings = {
    interpolate : /\{\{(.+?)\}\}/g
};

var template = function(name) {
    return _.template($('#'+name+'-template').html());
};

$(document).ready(function(){
    AlteredGene.boot($('#main'));
});

//    $('#data-set-table').dataTable({
//                    "sDom": '<"H"fr>t<"F"<"datatable-paging"pil>>', // selectable columns
//                    "bJQueryUI": true,
//                    "bDestroy": true,
//                    "oLanguage": {
//                        "sInfo": "&nbsp;&nbsp;(_START_ to _END_ of _TOTAL_)&nbsp;&nbsp;",
//                        "sInfoFiltered": "",
//                        "sLengthMenu": "Show _MENU_ per page"
//                    },
//                    "iDisplayLength": -1,
//                    "aLengthMenu": [[5,10, 25, 50, 100, -1], [5, 10, 25, 50, 100, "All"]]
//                }).show();

var AlteredGene = {};

AlteredGene.CancerStudy = Backbone.Model.extend({
});

AlteredGene.CancerStudies = Backbone.Collection.extend({
    model: AlteredGene.CancerStudy,
    url: 'portal_meta_data.json',
    parse: function(metaData) {
        var ret = [];
        var map = metaData.cancer_studies;
        for (var id in map) {
            if (id==='all') continue;
            var arr = map[id];
            var cs = {};
            cs['id'] = id;
            cs['name'] = arr.name;
            ret.push(cs);
        }
        return ret;
    }
});

AlteredGene.Form = Backbone.View.extend({
    tagName: "form",
    template: template("form"),
    events: {"submit":"submit"},
    render: function() {
        this.$el.html(this.template());
        var view = new AlteredGene.CancerStudies.View();
        this.$('#cancer-study-selection').html(view.render().$el);
    },
    submit: function(event) {
        event.preventDefault();
        var studies = [];
        var studyCheckBoxes = this.$('#cancer-study-selection input:checkbox:checked');
        for (var i=0, len=studyCheckBoxes.length; i<len; i++) {
            studies.push(studyCheckBoxes[i].value);
        }
        var type = this.$('#data-type').val();
        var threshold = this.$('#threshold-number-samples').val();
        router.navigate("submit/"+studies.join(",")+"/"+type+"/"+threshold, {trigger: true});
    }
});

AlteredGene.CancerStudies.View = Backbone.View.extend({
    initialize: function() {
      this.cancerStudies = new AlteredGene.CancerStudies();
      this.cancerStudies.on('sync', this.render, this);
      this.cancerStudies.fetch();
    },
    render: function() {
        if (this.cancerStudies.length==0)
            this.$el.html("<img src=\"images/ajax-loader.gif\"/>");
        else
            this.$el.html("");
        this.cancerStudies.each(function(cancerStudy){
            var view = new AlteredGene.CancerStudy.View({model: cancerStudy});
            this.$el.append(view.render().$el);
        }, this);
        return this;
    }
});

AlteredGene.CancerStudy.View = Backbone.View.extend({
    template: template("cancer-study"),
    render: function() {
        this.$el.html(this.template(this.model.attributes));
            
        var id = this.model.get('id');
        if (id.search(/(merged)|(ccle)|(_pub)/)==-1)
            this.$('input').prop('checked',true);
            
        return this;
    }
});

AlteredGene.Alteration = Backbone.Model.extend({
});

AlteredGene.Alterations = Backbone.Collection.extend({
    initialize: function(models, options) {
        this.studies = options.studies;
        this.type = options.type;
        this.threshold = options.threshold;
    },
    model: AlteredGene.Alteration,
    url: 'mutations.json',
    parse: function(statistics) {
        var ret = [];
        for (var alteration in statistics) {
            var studyStatistics = statistics[alteration];
            var row = {};
            row['alteration'] = alteration;
            row['statistics'] = studyStatistics;
            
            var totalSamples = 0;
            for (var study in studyStatistics)
                totalSamples += studyStatistics[study];
            
            row['samples'] = totalSamples;
            
            ret.push(row);
        }
        return ret;
    }
});

$.fn.dataTableExt.oApi.fnReloadAjax = function ( oSettings, sNewSource, fnCallback, bStandingRedraw )
{
    if ( typeof sNewSource != 'undefined' && sNewSource != null )
    {
        oSettings.sAjaxSource = sNewSource;
    }
    this.oApi._fnProcessingDisplay( oSettings, true );
    var that = this;
    var iStart = oSettings._iDisplayStart;
    var aData = [];
 
    this.oApi._fnServerParams( oSettings, aData );
     
    oSettings.fnServerData( oSettings.sAjaxSource, aData, function(json) {
        /* Clear the old information from the table */
        that.oApi._fnClearTable( oSettings );
         
        /* Got the data - add it to the table */
        var aData =  (oSettings.sAjaxDataProp !== "") ?
            that.oApi._fnGetObjectDataFn( oSettings.sAjaxDataProp )( json ) : json;
         
        for ( var i=0 ; i<aData.length ; i++ )
        {
            that.oApi._fnAddData( oSettings, aData[i] );
        }
         
        oSettings.aiDisplay = oSettings.aiDisplayMaster.slice();
        that.fnDraw();
         
        if ( typeof bStandingRedraw != 'undefined' && bStandingRedraw === true )
        {
            oSettings._iDisplayStart = iStart;
            that.fnDraw( false );
        }
         
        that.oApi._fnProcessingDisplay( oSettings, false );
         
        /* Callback user function - for event handlers etc */
        if ( typeof fnCallback == 'function' && fnCallback != null )
        {
            fnCallback( oSettings );
        }
    }, oSettings );
}

AlteredGene.Alterations.MissenseTable = Backbone.View.extend({
    template: template("datatables"),
    initialize: function(options) {
        this.alterations = new AlteredGene.Alterations([],options);
        this.alterations.on('sync', this.render, this);
        this.alterations.fetch({data:options});
    },
    render: function() {
        if (this.alterations.length==0) {
            this.$el.html("<img src=\"images/ajax-loader.gif\"/> Calculating ...");
            return;
        }
        
        var alterations = this.alterations;
        var tableId = "alteration-table";
        this.$el.html(this.template({table_id:tableId}));
        var oTable = this.$('#'+tableId).dataTable({
            "aoColumns": [
                {"sTitle": "Alteration", "mDataProp":"alteration"},
                {"sTitle":"Samples", "mDataProp":"samples"},
                {"sTitle":"Studies", "mDataProp":"statistics"},
            ],
            sAjaxSource: "",
            sAjaxDataProp: "",
            fnServerData: function( sSource, aoData, fnCallback ){
                console.log(alterations.toJSON());
                fnCallback(alterations.toJSON());
            }
        });
        oTable.fnReloadAjax();
    }
});

AlteredGene.Router = Backbone.Router.extend({
    initialize: function(options) {
        this.el = options.el
    },
    routes: {
        "": "form",
        "submit/:studies/:type/:threshold": "submit"
    },
    form: function() {
        var view = new AlteredGene.Form();
        view.render();
        this.el.empty();
        this.el.append(view.el);
    },
    submit: function(studies, type, threshold) {
        alert("submit/"+studies+"/"+type+"/"+threshold);
        this.el.empty();
        if (type=="missense") {
            var view = new AlteredGene.Alterations.MissenseTable(
                {
                    'cmd': 'statistics',
                    'cancer_study_id': studies,
                    'type': type,
                    'threshold_samples': threshold
                });
            view.render();
            this.el.append(view.el);
        } else {
            this.el.append("under development");
        }
    }
});

var router;
AlteredGene.boot = function(container) {
    container = $(container);
    router = new AlteredGene.Router({el: container});
    Backbone.history.start();
}

</script>

</body>
</html>
