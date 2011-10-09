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

    app.model.StationSelection = Backbone.Model.extend({
        defaults: {
            selected: undefined
        }
    })

    app.model.TrainSearchResult = Backbone.Model.extend({
    });
    app.model.TrainSearchResults = Backbone.Collection.extend({
        model: app.model.TrainSearchResult
    });
    app.model.TrainSearch = Backbone.Model.extend({
        initialize: function() {
            _.bindAll(this);
            this.isSearching = false;
            this.set({
                results: new app.model.TrainSearchResults
            });
            this.setCollectionUrl();
            this.bind("change:to", this.setCollectionUrl);
            this.bind("change:from", this.setCollectionUrl);
            this.get("results").bind("reset", this.resultsDone);
        },
        search: function() {
            console.log("Starting search to url " + this.get("results").url);
            this.isSearching = true;
            this.trigger("change:results", this.get("results"));
            this.get("results").fetch();
        },
        setCollectionUrl: function() {
            this.get("results").url = "/api/trains/search.json?from=" + this.get("from") + "&to=" + this.get("to");
            console.log("Updated search url to " + this.get("results").url);
        },
        resultsDone: function(x) {
            this.isSearching = false;
            this.trigger("change:results", x);
        },
        isValidSearch: function() {
            return typeof(this.get("from")) != "undefined" &&
                typeof(this.get("to")) != "undefined"
        }
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
            this.model.get("stations").bind("add", this.stationAdded);
            this.model.get("stations").bind("reset", this.stationsReset);
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
        onChange: function(x) {
            var selectedText = this.$("option:selected").text();
            var selectedStation = this.model.get("stations").find(function(s) {
                return s.get("name") == selectedText
            });
            this.model.set({
                selected: selectedStation
            });
        }
    });

    app.view.TrainSearchResultLoading = Backbone.View.extend({
        tagName: "li",
        template: _.template($("#train-loading-tmpl").html()),
        render: function() {
            $(this.el).html(this.template({
                name: this.model.get("name"),
                url: this.model.get("url")
            }));
        }
    });

    app.view.TrainSearchResults = Backbone.View.extend({
        initialize: function() {
            _.bindAll(this);
            this.model.bind("change:results", this.resultsChange);
        },
        resultsChange: function(model) {
            console.log("results change, model: " + JSON.stringify(model));
            this.render();
        },
        render: function() {
            if (!this.model.isValidSearch()) {
                this.$("#loading").hide();
                this.$("#results").hide();
            } else if (this.model.isSearching) {
                this.$("#results").hide();
                this.$("#loading").show();
            } else {
                var results = this.model.get("results");
                this.$("#realtime-result-count").html(results.size());
                results.each(this.renderSearchRow);
                this.$("#loading").hide();
                this.$("#results").show();
            }
        },
        renderSearchRow: function(result) {
            var view = new app.view.TrainSearchResultLoading({ model: result });
            view.render();
            this.$("#train-list").append(view.el);
        }
    });

    app.view.MainView = Backbone.View.extend({
        el: $("#app"),
        initialize: function() {
            var stations = new app.model.Stations();

            var fromSelection = new app.model.StationSelection({
                stations: stations
            });
            var toSelection = new app.model.StationSelection({
                stations: stations
            });
            var trainSearch = new app.model.TrainSearch();

            fromSelection.bind("change:selected", function(selection) {
                trainSearch.set({
                    from: selection.get("selected").get("name")
                });
                if (trainSearch.isValidSearch()) {
                    trainSearch.search();
                }
            });
            toSelection.bind("change:selected", function(selection) {
                trainSearch.set({
                    to: selection.get("selected").get("name")
                });
                if (trainSearch.isValidSearch()) {
                    trainSearch.search();
                }
            });
            new app.view.StationSelect({
               el: $("#from"),
               model: fromSelection
            });
            new app.view.StationSelect({
                el: $("#to"),
                model: toSelection
            });
            new app.view.TrainSearchResults({
                el: $("#search-results"),
                model: trainSearch
            })
            stations.fetch();

        }
    });

    var mainView = new app.view.MainView();
    $(".chzn-select").chosen();
    $("#app").show();
});
