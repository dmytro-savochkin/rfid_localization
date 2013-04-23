function plotKGraph(data, id) {
    console.log(data);
    var graph_data = [
        {data: data[0], color: 'red', label: 'unweighted'},
        {data: data[1], color: 'green', label: 'weighted'}
    ];

    var options = {
        yaxis: {
            min:20,
            max:60,
            ticks: 10
        },
        xaxis: {
            min:1,
            max:20,
            ticks: 20
        }
    }

    $.plot(id, graph_data, options);
}


function plotCdfChart(data, id) {
    data[0].push([500, 1])
    data[1].push([500, 1])

    var graph_data = [
        {data: data[0], color: 'red', label: 'trilateration'},
        {data: data[1], color: 'green', label: 'kNN'}
    ];

    var options = {
        yaxis: {
            min:0,
            max:1,
            ticks: 10
        },
        xaxis: {
            min:0,
            max:300,
            ticks: 20
        }
    }

    $.plot(id, graph_data, options);
}


function plotMapChart(tags, estimates, id) {
    var options = {
        yaxis: {
            min:0,
            max:505,
            ticks: 10
        },
        xaxis: {
            min:0,
            max:505,
            ticks: 10
        },
        series: {
            points: {
                show: true,
                radius: 5
            }
        },
        grid: {
            hoverable: true
        }
    }



    data = [
        {
            label: 'positions',
            data: tags,
            color: 'rgba(255, 0, 0, 0.4)',
            points: {
                symbol: "circle",
                fill: true,
                fillColor: "rgba(255, 0, 0, 0.4)"
            }
        },
        {
            label: 'estimates',
            data: estimates,
            color: "rgba(0, 0, 255, 0.4)",
            points: {
                symbol: "square",
                fill: true,
                fillColor: "rgba(0, 0, 255, 0.4)"
            }
        }
    ]

    for(var i = 0; i < tags.length; i++) {
        data.push({ data: [tags[i], estimates[i]], color: "rgba(110, 110, 110, 0.1)",  lines: {show: true}, points: {show: false} } )
    }

    $.plot(id, data, options);
}