function globalUnderscoreSetup() {
    _.templateSettings = {
      interpolate : /\{\{(.+?)\}\}/g
    };
}

function parseTime(timeStr) {
    var d = new Date();
    var isBeforeMidnight = d.getHours() >= 18;
    var time = timeStr.match(/(\d+)+:(\d+)+/);
    d.setHours(parseInt(time[1]));
    d.setMinutes(parseInt(time[2]));
    d.setSeconds(0);
    d.setMilliseconds(0);
    // Move to next day in case we're right before midnight and time is over midnight
    if (isBeforeMidnight && d.getHours() <= 6) {
        var msecsInADay = 86400000;
        d = new Date(d.getTime() + msecsInADay);
    }
    return d;
}

function formatTime(time) {
    var h = time.getHours();
    var m = time.getMinutes();
    var hStr = (h < 10) ? "0" + h : h;
    var mStr = (m < 10) ? "0" + m : m;
    return hStr + ":" + mStr;
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
    });
    app.model.Train = Backbone.Model.extend({
        initialize: function() {
            _.bindAll(this);
            this.bind("change", this.onLoaded);
        },
        onLoaded: function(x) {
            console.log(JSON.stringify(this));
        },
        url: function() {
            return "/api/train/" + this.get("id") + ".json";
        },
        startStation: function() {
            return _(this.get("stations")).first();
        },
        endStation: function() {
            return _(this.get("stations")).last();
        },
        stationByName: function(name) {
            return _(this.get("stations")).find(function(s) { return s.name == name });
        },
        lastKnownStation: function() {
            return _(this.get("stations"))
                .chain()
                .clone() // required because reverse does not copy
                .reverse()
                .find(function(s) { return s.actual_departure != null })
                .value();
        },
        lateMinutes: function() {
            var lastStation = this.lastKnownStation();
            if (typeof(lastStation) != "undefined") {
                var scheduled = parseTime(lastStation.scheduled_departure);
                var actual = parseTime(lastStation.actual_departure);
                var diffInMs = actual.getTime() - scheduled.getTime();
                return diffInMs / 1000 / 60;
            } else {
                return 0;
            }
        }
    });
    app.model.TrainSearchResult = Backbone.Model.extend({
        defaults: {
            from: null,
            to: null,
            train: null
        }
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
    });
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
    app.view.TrainSearchResult = Backbone.View.extend({
        tagName: "li",
        loadingTemplate: _.template($("#train-loading-tmpl").html()),
        fullTemplate: _.template($("#train-tmpl").html()),
        initialize: function() {
            _.bindAll(this);
            this.model.get("train").bind("change", this.render);
        },
        render: function() {
            if (!this.model.get("train").get("full_info")) {
                this.renderLoading(this.model);
            } else {
                this.renderFull(this.model);
            }
        },
        renderLoading: function(resultModel) {
            var train = resultModel.get("train");
            $(this.el).html(this.loadingTemplate({
                name: train.get("name"),
                url: train.get("url")
            }));
            train.fetch();
        },
        renderFull: function(resultModel) {
            var train = resultModel.get("train");
            var fromStation = train.stationByName(resultModel.get("from"));
            var toStation = train.stationByName(resultModel.get("to"));
            var lastKnownStation = train.lastKnownStation();
            var lastKnownInfo = (typeof(lastKnownStation) == "undefined") ?
                "Ei tietoja" :
                "Viimeksi " + lastKnownStation.name + " klo " + lastKnownStation.actual_departure;
            var lateMinutes = train.lateMinutes();
            $(this.el).html(this.fullTemplate({
                name: train.get("name"),
                url: train.get("url"),
                startStation: train.startStation().name,
                endStation: train.endStation().name,
                schedDeparture: fromStation.scheduled_departure,
                schedArrival: toStation.scheduled_arrival,
                lastKnownInfo: lastKnownInfo,
                lateInfo: lateMinutes
            }));

            if (lateMinutes == 0) {
                this.$(".late-info").hide();
            } else {
                this.$(".late-info").show();
            }

            var now = new Date();
            var scheduledDeparture = parseTime(fromStation.scheduled_departure);
            var estimatedDeparture = new Date(scheduledDeparture.getTime() + lateMinutes * 60000);

            if (estimatedDeparture.getTime() <= now) {
                $(this.el).addClass("gone-already");
            }
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
                var now = new Date();
                var results = this.model.get("results");
                this.$("#realtime-result-count").html(results.size());
                this.$("#realtime-result-time").html(formatTime(now));
                this.$("#train-list").html("");
                results.each(this.renderSearchRow);
                this.$("#loading").hide();
                this.$("#results").show();
            }
        },
        renderSearchRow: function(train) {
            var resultModel = new app.model.TrainSearchResult({
                from: this.model.get("from"),
                to: this.model.get("to"),
                train: new app.model.Train(train)
            });
            var view = new app.view.TrainSearchResult({
                model: resultModel
            });
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
            });
            stations.fetch();
        }
    });

    var mainView = new app.view.MainView();
    $(".chzn-select").chosen();
    $("#app").show();
    $("#from_chzn").focus();
});
