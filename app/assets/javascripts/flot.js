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
        yaxis: {min:0, max:1, ticks: 10, axisLabel: 'P', axisLabelUseCanvas: true},
        xaxis: {min:0, max:120, ticks: 20, axisLabel: 'average error', axisLabelUseCanvas: false}
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

function plotMapChart(tags, id) {
    var positions = []
    var estimates = []
    for(var tag_id in tags) {
        positions.push( [tags[tag_id]['position']['x'], tags[tag_id]['position']['y']] )
        estimates.push( [tags[tag_id]['estimate']['x'], tags[tag_id]['estimate']['y']] )
    }

    var options = {
        yaxis: {min:0, max:505, ticks: 10},
        xaxis: {min:0, max:505, ticks: 10},
        series: {
            points: {show: true, radius: 5}
        },
        grid: {hoverable: true, clickable: true}
    }



    var algorithms = [
        {
            label: 'positions',
            data: positions,
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

    for(tag_id in tags) {
        algorithms.push(
            {
                tag_id: tag_id,
                data: [
                    [tags[tag_id]['position']['x'], tags[tag_id]['position']['y']],
                    [tags[tag_id]['estimate']['x'], tags[tag_id]['estimate']['y']]
                ],
                color: "rgba(110, 110, 110, 0.1)",
                lines: {show: true},
                points: {show: false}
            }
        )
    }


    var plot = $.plot(id, algorithms, options)


    var previousPoint = null;
    $(id).bind("plothover", function (event, pos, item) {
        if (item) {
            if (previousPoint != item.dataIndex) {
                previousPoint = item.dataIndex;
                $("#tooltip").remove();
                var x = item.datapoint[0].toFixed(1),
                    y = item.datapoint[1].toFixed(1);

                showTooltip(item.pageX, item.pageY,
                    item.series.tag_id + " (" + x + ", " + y + ")");
            }
        } else {
            $("#tooltip").remove();
            previousPoint = null;
        }
    });
}



function showTooltip(x, y, contents) {
    $("<div id='tooltip'>" + contents + "</div>").css({
        position: "absolute",
        display: "none",
        top: y + 5,
        left: x + 5,
        border: "1px solid #fdd",
        padding: "2px",
        "background-color": "#fee",
        opacity: 0.80
    }).appendTo("body").fadeIn(200);
}