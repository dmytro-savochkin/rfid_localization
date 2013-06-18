var algorithms = {}
var k_graph_data = undefined

function startMainPlotting() {
    var mapCharOptions = {
        legend: {show: false},
        yaxis: {min:0, max:505, ticks: 10},
        xaxis: {min:0, max:505, ticks: 10},
        series: {
            points: {show: true, radius: 5}
        },
        grid: {hoverable: true, clickable: true}
    }



    plotCdfAndHistogram(algorithms, '#cdf_div', '#histogram_div')
    plotMaps(algorithms)

    if (k_graph_data != undefined) {
        //plotKGraph(k_graph_data, '#k_graph_div')
    }


    $('#show_tag').click(function(){
        var tag_code = '00000000000000000000' + $('#tag_id').val()
        for(var algorithm_name in algorithms)break;
        if (algorithms[algorithm_name]['map'][tag_code] != undefined) {
            $('#single_tag_map').show()
            plotTagAtGeneralMap(tag_code, algorithms)
        }
    })
















    function setMapHoverHandler(div_id, field_to_show) {
        var previousPoint = null;
        $(div_id).bind("plothover", function (event, pos, item) {
            if (item) {
                if (previousPoint != item.dataIndex) {
                    previousPoint = item.dataIndex;
                    $("#map_hover_tip").remove();
                    var x = item.datapoint[0].toFixed(1),
                        y = item.datapoint[1].toFixed(1);

                    showMapHoverTip(
                        item.pageX, item.pageY,
                        item.series[field_to_show] + " (" + x + ", " + y + ")"
                    )
                }
            } else {
                $("#map_hover_tip").remove();
                previousPoint = null;
            }
        });
    }
    function showMapHoverTip(x, y, contents) {
        $("<div id='map_hover_tip'>" + contents + "</div>").css({
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

    function plotTagAtGeneralMap(tag_id, algorithms) {
        var div_id = '#general_map'

        var data = [{
            algorithm: 'true position',
            data: undefined,
            color: 'rgba(255, 0, 0, 0.4)',
            points: {
                symbol: "circle",
                fill: true,
                fillColor: "rgba(255, 0, 0, 0.4)"
            }
        }]

        var fill_color = "rgba(100, 100, 100, 0.5)";
        for(var algorithm_name in algorithms) {
            if (algorithm_name.substring(0,8) == 'wknn_rss')fill_color = "rgba(0, 0, 200, 0.7)";
            if (algorithm_name.substring(0,7) == 'wknn_rr')fill_color = "rgba(100, 0, 140, 0.7)";
            if (algorithm_name.substring(0,5) == 'zonal')fill_color = "rgba(0, 200, 0, 0.7)";

            if(data[0]['data'] == undefined)
                data[0]['data'] = [[
                    algorithms[algorithm_name]['map'][tag_id]['position']['x'],
                    algorithms[algorithm_name]['map'][tag_id]['position']['y']
                ]]
            data.push({
                algorithm: algorithm_name,
                data: [[
                    algorithms[algorithm_name]['map'][tag_id]['estimate']['x'],
                    algorithms[algorithm_name]['map'][tag_id]['estimate']['y']
                ]],
                color: "rgba(0, 0, 200, 0.5)",
                lines: {show: false},
                points: {show: true, fill: true, fillColor: fill_color}
            })
        }


        $.plot(div_id, data, mapCharOptions)
        setMapHoverHandler(div_id, 'algorithm')
    }

    function plotMaps(algorithms) {
        for(var algorithm_name in algorithms) {
            var div_id = '#' + algorithm_name + '_map'
            var data = algorithms[algorithm_name]['map']

            plotMapChart(data, div_id)
        }
    }

    function plotMapChart(tags, div_id) {
        var positions = []
        var estimates = []
        for(var tag_id in tags) {
            positions.push( [tags[tag_id]['position']['x'], tags[tag_id]['position']['y']] )
            estimates.push( [tags[tag_id]['estimate']['x'], tags[tag_id]['estimate']['y']] )
        }

        var algorithms = [
            {
                label: 'positions',
                data: positions,
                color: 'rgba(255, 0, 0, 0.4)',
                points: {symbol: "square", fill: true, fillColor: "rgba(255, 0, 0, 0.4)"}
            },
            {
                label: 'estimates',
                data: estimates,
                color: "rgba(0, 0, 255, 0.4)",
                points: { symbol: "cross", fill: true, fillColor: "rgba(0, 0, 255, 0.4)", radius: 7}
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

        $.plot(div_id, algorithms, mapCharOptions)
        setMapHoverHandler(div_id, 'tag_id')
    }
















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







    function plotCdfAndHistogram(data, cdf_div_id, histogram_div_id) {
        var lines_options = [
            {color : 'rgba(0, 255, 0, 0.8)', lineWidth: 1, dashPattern: [25,5], symbol : 'triangle'},
            {color : 'rgba(0, 0, 255, 0.8)', lineWidth: 2, dashPattern: [15,4], symbol : 'cross'},
            {color : 'rgba(255, 0, 0, 0.8)', lineWidth: 6, dashPattern: [4,4], symbol : 'diamond'},
            {color : 'black', lineWidth: 2, dashPattern: [1,0], symbol : 'square'},
            {color : 'rgba(255, 0, 255, 0.8)', lineWidth: 3, dashPattern: [7,3], symbol : 'diamond'},
            {color : 'grey', lineWidth: 3, dashPattern: [3,3], symbol : 'circle'}
        ]



        var cdf_graph_data = []
        var histogram_graph_data = []

        var line_id = 0
        for(var index in data) {
            if(line_id >= lines_options.length)
                line_id = 0

            data[index]['cdf'].push([500, 1])
            cdf_graph_data.push(
                {
                    data: data[index]['cdf'],
                    label: index,
                    color: lines_options[line_id].color,
                    lines: {
                        show: true,
                        lineWidth: lines_options[line_id].lineWidth,
                        dashPattern: lines_options[line_id].dashPattern
                    },
                    points: {show: false, radius: 2, symbol: lines_options[line_id].symbol, fill: false}
                }
            )

            histogram_graph_data.push(
                {
                    data: data[index]['histogram'],
                    label: index,
                    color: lines_options[line_id].color,
                    bars: {
                        show: true,
                        lineWidth: lines_options[line_id].lineWidth,
                        dashPattern: lines_options[line_id].dashPattern
                    },
                    lines: {show: false},
                    points: {show: false, radius: 2, symbol: lines_options[line_id].symbol, fill: false}
                }
            )
            line_id++
        }



        var labelFormatter = function(label, series) {
            return '<span style="font-size:18px;">' + label + '</span>';
        }
        var cdf_options = {
            legend: {show: true, position: 'se', labelFormatter: labelFormatter},
            yaxis: {min:0, max:1, ticks: 10, axisLabel: 'P', axisLabelUseCanvas: true},
            xaxis: {min:0, max:150, ticks: 20, axisLabel: 'mean error, cm', axisLabelUseCanvas: false}
        }
        var histogram_options = {
            legend: {show: true, position: 'ne', labelFormatter: labelFormatter},
            bars: { show: true, barWidth: 5, fill: 0.4 },
            yaxis: {min:0, max:30, ticks: 10, axisLabel: 'P', axisLabelUseCanvas: true},
            xaxis: {min:0, max:150, ticks: 20, axisLabel: 'mean error, cm', axisLabelUseCanvas: false}
        }


        $.plot(cdf_div_id, cdf_graph_data, cdf_options)
        $.plot(histogram_div_id, histogram_graph_data, histogram_options)
    }



}










