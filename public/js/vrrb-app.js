//Backbone.sync = function(method, model) {
//  alert(method + ": " + model.url);
//};
function globalUnderscoreSetup() {
    _.templateSettings = {
      interpolate : /\{\{(.+?)\}\}/g
    };
}


$(document).ready(function() {
    globalUnderscoreSetup();

    window.app = {
        model: {},
        view: {}
    };

    var CHOSEN_UPDATE_EVENT = "liszt:updated";

    app.model.Stations = Backbone.Collection.extend({
        url: "/api/stations.json"
    });

    app.view.StationOption = Backbone.View.extend({
        tagName: "option",
        render: function() {
            $(this.el).html(this.model.get("name"));
        }
    })

    app.view.StationSelect = Backbone.View.extend({
        initialize: function() {
            _.bindAll(this);
            this.model.bind("add", this.stationAdded);
            this.model.bind("reset", this.stationsReset);
        },
        events: {
            "change": "onChange"
        },
        stationsReset: function(s) {
            s.each(this.renderSingleStation);
            $(this.el).trigger(CHOSEN_UPDATE_EVENT);
        },
        stationAdded: function(s) {
            this.renderSingleStation(s);
            $(this.el).trigger(CHOSEN_UPDATE_EVENT);
        },
        renderSingleStation: function(s) {
            var view = new app.view.StationOption({model: s});
            view.render();
            $(this.el).append(view.el);
        },
        onChange: function() {
            console.log("Change in selection");
        }
    });

    app.view.MainView = Backbone.View.extend({
        el: $("#app"),
        initialize: function() {
            var stations = new app.model.Stations();
            var fromSelect = new app.view.StationSelect({
                el: $("#from"),
                model: stations
            });
            var toSelect = new app.view.StationSelect({
                el: $("#to"),
                model: stations
            });
            stations.fetch();
        }
    });

    var mainView = new app.view.MainView();
    $(".chzn-select").chosen();
    $("#app").show();
});
