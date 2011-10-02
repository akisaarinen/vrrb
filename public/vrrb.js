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
