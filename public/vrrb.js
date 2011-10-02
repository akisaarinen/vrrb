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
    ui_addTrainDetailsToSearchResults(train)
}

function handleTrainSearch(trains) {
    ui_hideLoading()
    ui_clearSearchResults()
    _(trains).each(function(train) {
        ui_addTrainToSearchResults(train)
        api_train_details(train, handleSingleTrainResult)
    })
    ui_showSearchResults(trains.length)
}

function train_lastKnownStation(train) {
    var lastKnownStation = _(train.stations).chain()
        .reverse()
        .detect(function(s) {
            return s.actual_departure != null
        })
        .value()
    console.log(lastKnownStation)
    if (typeof(lastKnownStation) != "undefined") {
        return lastKnownStation
    } else {
        return null
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

function ui_showSearchResults(realTimeResultCount) {
    $("#realtime-result-count").html(realTimeResultCount)
    $("#search-results").show()
}

function ui_addTrainToSearchResults(train) {
    $("#train-list").append(
        "<li class=\"train_" + train.id + "\">" +
            "<div class=\"name\">" + train.name + "</div>"+
            "<div class=\"loading-details\">(haetaan tarkempia tietoja)</div>" +
        "</li>")
}

function ui_addTrainDetailsToSearchResults(train) {
    ui_hideLoadingDetailsForTrain(train.id)
    var elem = $("#train-list .train_" + train.id)
    var lastKnownStation = train_lastKnownStation(train)
    var text = "Ei tietoja"
    if (lastKnownStation) {
        text = "Viimeksi @" + lastKnownStation.name + " kello " + lastKnownStation.actual_departure
    }
    elem.append("<div class=\"last-known-station\">" + text + "</div>")
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

        doTest()
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

function doTest() {
    var testTrains = [
        {"update_time":"2.10.2011, klo 21:01.","stations":[{"actual_departure":null,"scheduled_arrival":null,"actual_arrival":null,"name":"Vantaankoski","code":null,"scheduled_departure":"20:41"},{"actual_departure":null,"scheduled_arrival":"20:42","actual_arrival":null,"name":"Martinlaakso","code":null,"scheduled_departure":"20:42"},{"actual_departure":null,"scheduled_arrival":"20:44","actual_arrival":null,"name":"Louhela","code":null,"scheduled_departure":"20:44"},{"actual_departure":null,"scheduled_arrival":"20:46","actual_arrival":null,"name":"Myyrmäki","code":null,"scheduled_departure":"20:46"},{"actual_departure":null,"scheduled_arrival":"20:48","actual_arrival":null,"name":"Malminkartano","code":null,"scheduled_departure":"20:48"},{"actual_departure":null,"scheduled_arrival":"20:50","actual_arrival":null,"name":"Kannelmäki","code":null,"scheduled_departure":"20:50"},{"actual_departure":null,"scheduled_arrival":"20:52","actual_arrival":null,"name":"Pohjois-Haaga","code":null,"scheduled_departure":"20:52"},{"actual_departure":"20:54","scheduled_arrival":"20:54","actual_arrival":"20:54","name":"Huopalahti","code":null,"scheduled_departure":"20:54"},{"actual_departure":null,"scheduled_arrival":"20:56","actual_arrival":null,"name":"Ilmala","code":null,"scheduled_departure":"20:56"},{"actual_departure":null,"scheduled_arrival":"20:58","actual_arrival":null,"name":"Pasila","code":null,"scheduled_departure":"20:58"},{"actual_departure":"21:03","scheduled_arrival":"21:03","actual_arrival":"21:03","name":"Helsinki","code":null,"scheduled_departure":null}],"name":"M","url":"http://ext-service.vr.fi/juku/juna.action?lang=fi&junalaji=ll&junanro=8968","id":"8968"},
        {"update_time":"2.10.2011, klo 21:16.","stations":[{"actual_departure":"21:07","scheduled_arrival":null,"actual_arrival":null,"name":"Helsinki","code":null,"scheduled_departure":"21:07"},{"actual_departure":null,"scheduled_arrival":"21:12","actual_arrival":null,"name":"Pasila","code":null,"scheduled_departure":"21:12"},{"actual_departure":"21:15","scheduled_arrival":"21:15","actual_arrival":"21:15","name":"Huopalahti","code":null,"scheduled_departure":"21:15"},{"actual_departure":null,"scheduled_arrival":"21:19","actual_arrival":null,"name":"Leppävaara","code":null,"scheduled_departure":"21:19"},{"actual_departure":null,"scheduled_arrival":"21:21","actual_arrival":null,"name":"Kilo","code":null,"scheduled_departure":"21:21"},{"actual_departure":null,"scheduled_arrival":"21:23","actual_arrival":null,"name":"Kera","code":null,"scheduled_departure":"21:23"},{"actual_departure":null,"scheduled_arrival":"21:26","actual_arrival":null,"name":"Kauniainen","code":null,"scheduled_departure":"21:26"},{"actual_departure":null,"scheduled_arrival":"21:28","actual_arrival":null,"name":"Koivuhovi","code":null,"scheduled_departure":"21:28"},{"actual_departure":null,"scheduled_arrival":"21:30","actual_arrival":null,"name":"Tuomarila","code":null,"scheduled_departure":"21:30"},{"actual_departure":null,"scheduled_arrival":"21:32","actual_arrival":null,"name":"Espoo","code":null,"scheduled_departure":"21:32"},{"actual_departure":null,"scheduled_arrival":"21:35","actual_arrival":null,"name":"Kauklahti","code":null,"scheduled_departure":"21:35"},{"actual_departure":null,"scheduled_arrival":"21:40","actual_arrival":null,"name":"Masala","code":null,"scheduled_departure":"21:40"},{"actual_departure":null,"scheduled_arrival":"21:47","actual_arrival":null,"name":"Kirkkonummi","code":null,"scheduled_departure":null}],"name":"S","url":"http://ext-service.vr.fi/juku/juna.action?lang=fi&junalaji=ll&junanro=8573","id":"8573"},
        {"update_time":"2.10.2011, klo 0:03.","stations":[{"actual_departure":null,"scheduled_arrival":null,"actual_arrival":null,"name":"Vantaankoski","code":null,"scheduled_departure":"21:41"},{"actual_departure":null,"scheduled_arrival":"21:42","actual_arrival":null,"name":"Martinlaakso","code":null,"scheduled_departure":"21:42"},{"actual_departure":null,"scheduled_arrival":"21:44","actual_arrival":null,"name":"Louhela","code":null,"scheduled_departure":"21:44"},{"actual_departure":null,"scheduled_arrival":"21:46","actual_arrival":null,"name":"Myyrmäki","code":null,"scheduled_departure":"21:46"},{"actual_departure":null,"scheduled_arrival":"21:48","actual_arrival":null,"name":"Malminkartano","code":null,"scheduled_departure":"21:48"},{"actual_departure":null,"scheduled_arrival":"21:50","actual_arrival":null,"name":"Kannelmäki","code":null,"scheduled_departure":"21:50"},{"actual_departure":null,"scheduled_arrival":"21:52","actual_arrival":null,"name":"Pohjois-Haaga","code":null,"scheduled_departure":"21:52"},{"actual_departure":null,"scheduled_arrival":"21:54","actual_arrival":null,"name":"Huopalahti","code":null,"scheduled_departure":"21:54"},{"actual_departure":null,"scheduled_arrival":"21:56","actual_arrival":null,"name":"Ilmala","code":null,"scheduled_departure":"21:56"},{"actual_departure":null,"scheduled_arrival":"21:58","actual_arrival":null,"name":"Pasila","code":null,"scheduled_departure":"21:58"},{"actual_departure":null,"scheduled_arrival":"22:03","actual_arrival":null,"name":"Helsinki","code":null,"scheduled_departure":null}],"name":"M","url":"http://ext-service.vr.fi/juku/juna.action?lang=fi&junalaji=ll&junanro=8986","id":"8986"}
        ]
    ui_showSearchResults(testTrains.length)
    _(testTrains).each(function(t) {
        ui_addTrainToSearchResults(t)
        ui_addTrainDetailsToSearchResults(t)
    })
}

