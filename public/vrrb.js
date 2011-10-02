function api_stations(callback) {
    $.get("/api/stations.json", callback)
}

function api_trains(from, to, callback) {
    $.get("/api/trains/search.json?from=" + from + "&to=" + to, callback)
}

function api_train_details(train, callback) {
    $.get("/api/train/" + train.id + ".json", callback)
}

function handleSingleTrainResult(train) {
    console.log("Handling results for " + train.id)
    ui_hideLoadingDetailsForTrain(train.id)
    ui_addTrainDetailsToSearchResults(train)
}

function handleTrainSearch(trains) {
    ui_hideLoading()
    ui_clearSearchResults()
    ui_setSearchResultCount(trains.length)
    _(trains).each(function(train) {
        ui_addTrainToSearchResults(train)
        api_train_details(train, handleSingleTrainResult)
    })
    ui_showSearchResults()
}

function train_lastKnownStation(train) {
    console.log(JSON.stringify(train.stations))
    var lastKnownStation = _(train.stations).chain().reverse().detect(function(s) {
        console.log("s="+ JSON.stringify(s))
        s.actual_departure != null
    }).value()
    if (typeof(lastKnownStation) != "undefined") {
        return lastKnownStation
    } else {
        return _(train.stations).first
    }
}

function ui_showLoading() {
    $("#search-results").hide()
    $("#loading").show()
}

function ui_hideLoading() {
    $("#loading").hide()
}

function ui_hideLoadingDetailsForTrain(id) {
    $("#train-list .train_" + id + " .loading-details").hide()
}

function ui_clearSearchResults() {
    $("#train-list").html("")
}

function ui_showSearchResults() {
    $("#search-results").show()
}

function ui_setSearchResultCount(realTimeResultCount) {
    $("#realtime-result-count").html(realTimeResultCount)
}

function ui_addTrainToSearchResults(train) {
    $("#train-list").append(
        "<li class=\"train_" + train.id + "\">" +
            "<span class=\"name\">" + train.name + "</span>"+
            "<span class=\"loading-details\">(haetaan tarkempia tietoja)</span>" +
        "</li>")
}

function ui_addTrainDetailsToSearchResults(train) {
    var elem = $("#train-list .train_" + train.id)
    var lastKnownStation = train_lastKnownStation(train)
    elem.append("<span class=\"last-known-station\">" + JSON.stringify(lastKnownStation) + "</span>")
}

function ui_onSearchClick() {
    var from = $('#from option:selected').text()
    var to = $('#to option:selected').text()
    if (from != "" && to != "") {
        ui_showLoading()
        api_trains(from, to, handleTrainSearch)
    }
}

$(document).ready(function() {
    api_stations(function(stations) {
        _(stations).each(function (s) {
            var newOption = "<option>"+s.name+"</option>"
            $("#from").append(newOption)
            $("#to").append(newOption)
        })
        $("#search").show()
        $("#from").val("Kilo")
        $("#to").val("Helsinki")
        $(".chzn-select").chosen()
        $("#from").trigger("change")
    })
})


$('#from').change(function() {
    if (fromFieldValue() != "") {
        $("#to_chzn").show()
    } else {
        $("#to_chzn").hide()
    }
})

function emptyIfUndefined(text) {
    if (typeof(text) == "undefined") {
        return ""
    } else {
        return text
    }
}

function fromFieldValue() {
    var text = $("#from option:selected").text()
    return emptyIfUndefined(text)
}
function toFieldValue() {
    var text = $("#to option:selected").text()
    return emptyIfUndefined(text)
}
