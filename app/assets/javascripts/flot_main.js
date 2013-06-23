var algorithms = {}
var measurement_information = {}
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
    plotMaps(algorithms, measurement_information)

    if (k_graph_data != undefined) {
        //plotKGraph(k_graph_data, '#k_graph_div')
    }


    $('#show_tag').click(function(){
        var tag_index = $('#tag_id').val().toUpperCase()
        if (tag_index.length == 2)
            tag_index = '0' + tag_index.substring(0, 1) + '0' + tag_index.substring(1)
        if (tag_index.length == 3) {
            if(jQuery.isNumeric(tag_index.substring(1, 2)))
                tag_index = '0' + tag_index
            else
                tag_index = tag_index.substring(0, 2) + '0' + tag_index.substring(2)
        }
        var tag_found = false
        for(var algorithm_name in algorithms) {
            if (algorithms[algorithm_name]['map'][tag_index] != undefined) {
                tag_found = true
                break
            }
        }
        if (tag_found) {
            $('#single_tag_map').show()
            plotTagAtGeneralMap(tag_index, algorithms, measurement_information)
            show_mi_for_tag(tag_index, algorithms)
        }
    })



    function show_mi_for_tag(tag_index, algorithms) {
        var shown_reader_powers = []
        var added = 0

        $('#show_tag_mi').html('<strong>' + tag_index + '</strong><br><br>')
        var table = $("<table>", {id: "table_mi"})
        $('#show_tag_mi').append(table)
        var tr = $("<tr>", {id: "tr_mi"})
        table.append(tr)
        var td = $("<td>", {class: "td_mi"})
        tr.append(td)

        for(var algorithm_name in algorithms) {
            var reader_power = algorithms[algorithm_name]['work_zone']['reader_power']
            if(jQuery.inArray(reader_power, shown_reader_powers) == -1) {
                if(added >= 2) {
                    td = $("<td>", {class: "td_mi"})
                    tr.append(td)
                    added = 0
                }

                shown_reader_powers.push(reader_power)
                var answers = algorithms[algorithm_name]['tags'][tag_index]['answers']

                var data_list = {a_average: [], a_adaptive: [], rss: [], rr: []}
                for(var antenna_num in answers['a']['average']) {
                    if (answers['a']['average'][antenna_num])data_list['a_average'].push(antenna_num)
                    if (answers['a']['adaptive'][antenna_num])data_list['a_adaptive'].push(antenna_num)
                    if (answers['rss']['average'][antenna_num])
                        data_list['rss'].push(antenna_num + ': ' + answers['rss']['average'][antenna_num] + '<br>')
                    if (answers['rr']['average'][antenna_num])
                        data_list['rr'].push(antenna_num + ': ' + answers['rr']['average'][antenna_num] + '<br>')
                }

                td.append('<u><strong>Reader power: ' + reader_power + '</strong><u><br>')
                td.append('<strong>A</strong>')
                td.append('<br> Average: ')
                td.append(data_list['a_average'].join(', '))
                td.append('<br> Adaptive: ')
                td.append(data_list['a_adaptive'].join(', '))
                td.append('<br><strong>RSS</strong><br>')
                td.append(data_list['rss'].join(''))
                td.append('<strong>RR</strong><br>')
                td.append(data_list['rr'].join('') + '<br>')

                added += 1
            }

        }


    }













    function setMapHoverHandler(div_id, field_to_show) {
        var previousPoint = null;
        $(div_id).bind("plothover", function (event, pos, item) {
            if (item) {
                if (previousPoint != item.dataIndex) {
                    previousPoint = item.dataIndex;
                    $(".map_hover_tip").remove();
                    var x = item.datapoint[0].toFixed(1),
                        y = item.datapoint[1].toFixed(1);

                    showMapHoverTip(
                        item.pageX, item.pageY,
                        item.series[field_to_show] + " (" + x + ", " + y + ")"
                    )
                }
            } else {
                $(".map_hover_tip").remove();
                previousPoint = null;
            }
        });
    }


    function showMapHoverTip(x, y, contents) {
        var object = $("<div class='map_hover_tip'>" + contents + "</div>").css({
            position: "absolute",
            display: "none",
            top: y + 5,
            left: x + 5,
            border: "1px solid #fdd",
            padding: "2px",
            "background-color": "#fee",
            opacity: 0.80
        })
        object.appendTo("body").fadeIn(200)
    }











    function plotTagAtGeneralMap(tag_id, algorithms, measurement_information) {
        var div_id = '#general_map'

        var data = [{
            name: 'true position',
            data: undefined,
            color: 'rgba(255, 0, 0, 0.4)',
            points: {
                symbol: "circle",
                fill: true,
                radius: 10,
                fillColor: "rgba(255, 0, 0, 0.4)"
            }
        }]

        for(var algorithm_name in algorithms) {

            if(data[0]['data'] == undefined)
                data[0]['data'] = [[
                    algorithms[algorithm_name]['map'][tag_id]['position']['x'],
                    algorithms[algorithm_name]['map'][tag_id]['position']['y']
                ]]
            data.push({
                name: algorithm_name,
                data: [[
                    algorithms[algorithm_name]['map'][tag_id]['estimate']['x'],
                    algorithms[algorithm_name]['map'][tag_id]['estimate']['y']
                ]],
                color: "rgba(0, 0, 200, 0.5)",
                lines: {show: false},
                points: {symbol: "cross",show: true, radius: 10, fill: true}
            })
        }

        var antennae_hash = create_antennae_hash(measurement_information)
        for(var antenna_number in antennae_hash) {
            data.push(antennae_hash[antenna_number])
        }

        var plot = $.plot(div_id, data, mapCharOptions)
        setMapHoverHandler(div_id, 'name')

        var ctx = plot.getCanvas().getContext("2d");
        var offset = plot.getPlotOffset()
        var scaling = {x: plot.getAxes().xaxis.scale, y: plot.getAxes().yaxis.scale}

        for(var antenna_number in antennae_hash) {
            var canvas_coords = plot.p2c({
                x: antennae_hash[antenna_number].data[0][0],
                y: antennae_hash[antenna_number].data[0][1]
            })

            var ellipse_cx = offset.left + canvas_coords.left
            var ellipse_cy = offset.top + canvas_coords.top
            var ellipse_width = antennae_hash[antenna_number].coverage_sizes[0] * scaling.x
            var ellipse_height = antennae_hash[antenna_number].coverage_sizes[1] * scaling.y

            drawEllipse(ctx, ellipse_cx, ellipse_cy, ellipse_width, ellipse_height, -45, [200,0,0,0.1])
            drawText(ctx, ellipse_cx + 10, ellipse_cy + 10, antennae_hash[antenna_number].name, 24)
        }





    }





    function plotMaps(algorithms, measurement_information) {
        for(var algorithm_name in algorithms) {
            var div_id = '#' + algorithm_name + '_map'
            var data = algorithms[algorithm_name]['map']

            plotMapChart(data, div_id, measurement_information)
        }
    }

    function plotMapChart(tags, div_id, measurement_information) {
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

        var antennae_hash = create_antennae_hash(measurement_information)
        for(var antenna_number in antennae_hash) {
            algorithms.push(antennae_hash[antenna_number])
        }

        for(tag_id in tags) {
            algorithms.push(
                {
                    name: tag_id,
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
        setMapHoverHandler(div_id, 'name')
    }










    function create_antennae_hash(measurement_information) {
        var antennae_hash = []
        for(var antenna_number in measurement_information['work_zone']['antennae']) {
            var antenna = measurement_information['work_zone']['antennae'][antenna_number]

            antennae_hash.push(
                {
                    name: antenna_number,
                    coverage_sizes: [antenna.coverage_zone_width, antenna.coverage_zone_height],
                    data: [
                        [antenna.coordinates.x, antenna.coordinates.y]
                    ],
                    color: "rgba(110, 110, 110, 0.1)",
                    lines: {show: false},
                    points: {show: true, radius: 10, symbol: 'square', fill: true, fillColor: "rgba(0, 255, 0, 0.4)"}
                }
            )
        }
        return antennae_hash
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










