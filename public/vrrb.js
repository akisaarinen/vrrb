function fetchStations(callback) {
    $.get("/api/stations.json", callback)
}

function fetchTrainList(station) {
    function handleSingleTrain(t, status) {
        var selector = '#trainList .train_' + t.id
        $(selector + ' img.loader').hide();
        $(selector).append('(' + t.source + " - " + t.target + '), päivitetty ' + t.update_time)
    }

    function handleTrainList(trainList, status) {
        $('#loading').hide()
        $('#trainList .trainCount').html(trainList.length)

        for (var i = 0; i < trainList.length; i++) {
            var t = trainList[i]
            var jsonUrl = '/api/train/' + t.id + '.json'
            $('#trainList .trains').append('<li class="train_' + t.id + '"><a href="' + jsonUrl + '">' + t.name + ' (' + t.id + ') <img class="loader" src="/ajax-loader.gif"></a></li>')
            $.get(jsonUrl, handleSingleTrain)
        }

        $('#trainList .jsonContent').append("<pre>"+JSON.stringify(trainList)+"</pre>")
        $('#trainList').show()
    }

    $.get("/api/station/" + station + ".json", handleTrainList)
}

function searchClick() {
    var from = $('#from option:selected').text()
    var to = $('#to option:selected').text()
    if (from != "" && to != "") {
        doAjaxSearch(from, to)
    }
}

function doAjaxSearch(from, to) {
    alert(from + to)
}

$(document).ready(function() {
    fetchStations(function(data) {
        var raw_stations = JSON.parse(data)
        _(raw_stations).each(function (s) {
            var newOption = "<option>"+s.name+"</option>"
            $("#from").append(newOption)
            $("#to").append(newOption)
        })
        $("#search").show()
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
