var algorithms = {}
var k_graph_data = undefined

$(document).ready(function() {
    plotCdfChart(algorithms, '#cdf_div')
    plotMaps(algorithms)

    if (k_graph_data != undefined) {
        plotKGraph(k_graph_data, '#k_graph_div')
    }
})



function plotKGraph(data, id) {
    var graph_data = [
        {data: data[1], color: 'red', label: 'unweighted'},
        {data: data[0], color: 'green', label: 'weighted'}
    ];

    var options = {
        yaxis: {min:20, max:60, ticks: 10},
        xaxis: {min:1, max:20, ticks: 20, tickDecimals: 0}
    }

    $.plot(id, graph_data, options);
}


function plotCdfChart(data, id) {
    var graph_data = []

    for(var index in data) {
        data[index]['cdf'].push([500, 1])
        graph_data.push({data: data[index]['cdf'], label: index})
    }


    var options = {
        yaxis: {min:0, max:1, ticks: 10},
        xaxis: {min:0, max:150, ticks: 20}
    }

    $.plot(id, graph_data, options);
}


function plotMaps(algorithms) {
    for(var algorithm_name in algorithms) {
        var div_id = '#' + algorithm_name + '_map'
        var data = algorithms[algorithm_name]['map']

        plotMapChart(data, div_id)
    }
}

function plotMapChart(input, id) {
    var tags = input[0]
    var estimates = input[1]

    var options = {
        yaxis: {min:0, max:505, ticks: 10},
        xaxis: {min:0, max:505, ticks: 10},
        series: {
            points: {show: true, radius: 5}
        },
        grid: {hoverable: true}
    }



    var algorithms = [
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
        algorithms.push({ data: [tags[i], estimates[i]], color: "rgba(110, 110, 110, 0.1)",  lines: {show: true}, points: {show: false} } )
    }

    $.plot(id, algorithms, options)
}