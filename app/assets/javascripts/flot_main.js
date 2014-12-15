var algorithms = {}
var classifier = {}
var work_zone = {}
var trilateration_map_data = {}



function startMainPlotting() {
    var flotDrawer = new FlotDrawer(algorithms, work_zone, trilateration_map_data)
    flotDrawer.updateHeights(getHeightsMapSelectArray())


    function plotMapsAndDistributions() {
        flotDrawer.plotMaps()
        if ($('#cdf_div').length) flotDrawer.distribution_function.plotCdf('#cdf_div')
        if ($('#pdf_div').length) flotDrawer.distribution_function.plotPdf('#pdf_div')
    }


    plotMapsAndDistributions()
    createHandlersForMaps()



    $('#pdf_div').click(function() {
        flotDrawer.distribution_function.changePdfState('#pdf_div')
    })




    $('#algorithm_heights_select').change(function() {
        flotDrawer.updateHeights(getHeightsMapSelectArray())
        flotDrawer.updateSuitabilityTable()
        plotMapsAndDistributions()
        if( $('#joint_estimates_map').is(':visible') )
            plotJointEstimates()
        if($('#comparing_algorithms_map').is(':visible'))
            compareAlgorithms()
    })

    $('#joint_estimates_show_button').click(function() {
        plotJointEstimates()
    })

    function plotJointEstimates() {
        var tag_index = getTagIndexFromTextField('joint_estimates_input')
        if (getAlgorithmWithTag(tag_index)) {
            $('#joint_estimates_map').show()
            flotDrawer.drawJointEstimatesMap(tag_index)
            flotDrawer.showJointEstimatesMi(tag_index)
            flotDrawer.showJointEstimatesData(tag_index)
        }
    }

    $('#trilateration_show_button').click(function() {
        var tag_index = getTagIndexFromTextField('trilateration_input')
        if(trilateration_map_data['data'][tag_index] != undefined) {
            var algorithm_with_tag = getAlgorithmWithTag(tag_index)
            if(algorithm_with_tag) {
                var heights = flotDrawer.heights
                var tag_position = algorithms[algorithm_with_tag]['map'][heights][tag_index]['position']
                $('#trilateration_map').show()
                flotDrawer.drawTrilaterationColorMap(tag_position, tag_index)
            }
        }
    })

    $('#comparing_algorithms_show_button').click(compareAlgorithms)









    function compareAlgorithms() {
        var algorithms_to_compare = [
            algorithms[$('#algorithm_to_compare1').val()],
            algorithms[$('#algorithm_to_compare2').val()]
        ]
        if (algorithms_to_compare[0] != undefined && algorithms_to_compare[1] != undefined) {
            $('#comparing_algorithms_map').show()
            flotDrawer.drawComparingMap(algorithms_to_compare)
        }
    }





    function getHeightsMapSelectArray() {
        var heights_ary = $('#algorithm_heights_select').val().split('.')
        return heights_ary[0] - 1

    }


    function createHandlersForMaps() {
        for(var algorithm_name in algorithms) {
            var map_div_id = '#' + algorithm_name + '_map'
            $(map_div_id).bind("contextmenu", function () {
                return false;
            });
            $(map_div_id).mousedown(function(event) {
                var div_id = $(this).attr("id")
                var algorithm_name = div_id.split("_").slice(0, -1).join("_")
                switch (event.which) {
                    case 1:
                        flotDrawer.changeMapState(algorithm_name, true)
                        break;
                    case 3:
                        flotDrawer.changeMapState(algorithm_name, false)
                        break;
                    default:
                        alert('You have a strange mouse');
                }
            });
        }
    }

    function getAlgorithmWithTag(tag_index) {
        var heights = flotDrawer.heights
        for(var algorithm_name in algorithms) {
            if (algorithms[algorithm_name]['map'][heights][tag_index] != undefined)
                return algorithm_name
        }
        return false
    }


    function getTagIndexFromTextField(text_field_id) {
        var tag_index = $('#' + text_field_id).val().toUpperCase()

        var pattern = /[a-zA-Z]/g;
        if(pattern.test(tag_index)) {
            if (tag_index.length == 2)
                tag_index = '0' + tag_index.substring(0, 1) + '0' + tag_index.substring(1)
            if (tag_index.length == 3) {
                if(jQuery.isNumeric(tag_index.substring(1, 2)))
                    tag_index = '0' + tag_index
                else
                    tag_index = tag_index.substring(0, 2) + '0' + tag_index.substring(2)
            }
            return tag_index
        }
        else {
            return tag_index
        }
    }

}








var regressionDeviationsDistribution = function(deviations, reader_powers, ellipse_ratios, max_degrees) {
    var steps = 20

    for(var i in reader_powers) {
        var reader_power = reader_powers[i]
        for(var j in ellipse_ratios) {
            var ellipse_ratio = ellipse_ratios[j].toFixed(1)
            for(var k in max_degrees) {
                var max_degree = max_degrees[k].toFixed(1)
                var id = '#deviations_graph_' + ellipse_ratio.toString().replace(/\./, '_') + '_' + max_degree.toString().replace(/\./, '_') + '_' + reader_power.toString()

                if($(id).val() != undefined) {
                    var range = {}
                    range['min'] = Array.min(deviations[ellipse_ratio][max_degree][reader_power])
                    range['max'] = Array.max(deviations[ellipse_ratio][max_degree][reader_power])

                    var step_size = (range['max'] - range['min']) / steps
                    var current_shift = range['min']
                    var data = []

                    var max_absolute_deviation = Math.max(
                        Math.abs(Array.min(deviations[ellipse_ratio][max_degree][reader_power])),
                        Math.abs(Array.max(deviations[ellipse_ratio][max_degree][reader_power]))
                    )
                    var axis_width = Math.ceil(max_absolute_deviation / 5) * 5
                    if (axis_width < 20.0) axis_width = 20.0
                    var axis_height = 0.2

                    for(var j = 0; j < steps; j++) {
                        var rate_in_this_range = deviations[ellipse_ratio][max_degree][reader_power].filter(function(x){
                            return (x >= current_shift && x < (current_shift + step_size))
                        }).length / deviations[ellipse_ratio][max_degree][reader_power].length

                        if(rate_in_this_range > axis_height) {
                            axis_height = Math.ceil(rate_in_this_range * 10) / 10
                        }

                        data.push([current_shift, 0])
                        data.push([current_shift, rate_in_this_range])
                        data.push([current_shift + step_size, rate_in_this_range])
                        data.push([current_shift + step_size, 0])
                        current_shift += step_size
                    }

                    var j = 0
                    var graph_data = [
                        {data: data, color: 'red'}
                    ]
                    var options = {
                        yaxis: {min:0, max:axis_height, ticks: 5},
                        xaxis: {min:-axis_width, max:axis_width, ticks: 20, tickDecimals: 0}
                    }

                    $.plot(id, graph_data, options)
                }
            }
        }
    }
}

var regressionProbabilitiesDistances = function(data, nodes, reader_powers, ellipse_ratios) {
    var plotted_total_graph = false
    var options = {
        yaxis: {min:0, max:1.03, ticks: 11, tickDecimals: 1},
        xaxis: {min:0, max:600, ticks: 20, tickDecimals: 0}
    }
    for(var reader_power_index in reader_powers) {
        var reader_power = reader_powers[reader_power_index]
        for(var ellipse_ratio_index in ellipse_ratios) {
            var ellipse_ratio = ellipse_ratios[ellipse_ratio_index].toFixed(1)

            for(var previous_rp_answered_index in [true, false, 'null']) {
                var previous_rp_answered = [true, false, 'null'][previous_rp_answered_index]
                if(reader_power == 20 && previous_rp_answered == true) continue


                var current_nodes = []
                var current_data = data[reader_power][ellipse_ratio][previous_rp_answered]
                for(var node_i in nodes[reader_power][ellipse_ratio][previous_rp_answered]) {
                    current_nodes.push([node_i, nodes[reader_power][ellipse_ratio][previous_rp_answered][node_i]])
                }
                var graph_data = [
                    {data: current_data, color: 'red', lines: {lineWidth: 2, dashPattern: [7,0]}},
                    {data: current_nodes, color: 'grey', points:{show:true, radius: 1}}
                ]
                var id = '#probabilities_graph_' + reader_power + '_' + ellipse_ratio.replace(/\./, '') + '_' + previous_rp_answered.toString()

                $.plot(id, graph_data, options)
            }
            if(plotted_total_graph == false) {
                for(previous_rp_answered_index in [false, 'null']) {
                    previous_rp_answered = [false, 'null'][previous_rp_answered_index]

                    id = '#probabilities_graph_total_' + ellipse_ratio.replace(/\./, '') + '_' + previous_rp_answered.toString()

                    var current_nodes1 = []
                    var current_nodes2 = []
                    var current_nodes3 = []
                    for(var node_i in nodes[reader_power][ellipse_ratio][previous_rp_answered]) {
                        current_nodes1.push([node_i, nodes[reader_power][ellipse_ratio][previous_rp_answered][node_i]])
                    }
                    for(node_i in nodes[25][ellipse_ratio][previous_rp_answered]) {
                        current_nodes2.push([node_i, nodes[25][ellipse_ratio][previous_rp_answered][node_i]])
                    }
                    for(node_i in nodes[30][ellipse_ratio][previous_rp_answered]) {
                        current_nodes3.push([node_i, nodes[30][ellipse_ratio][previous_rp_answered][node_i]])
                    }
                    current_data = data[reader_power][ellipse_ratio][previous_rp_answered]
                    graph_data = [
//                    {data: current_data, color: 'red', label: '20', lines: {lineWidth: 2, dashPattern: [7,0]}},
                        {data: data[20][ellipse_ratio][previous_rp_answered], color: 'orange', label: '20', lines: {lineWidth: 2, dashPattern: [7,7]}},
                        {data: data[22][ellipse_ratio][previous_rp_answered], color: 'red', label: '22', lines: {lineWidth: 2, dashPattern: [7,0]}},
                        {data: data[24][ellipse_ratio][previous_rp_answered], color: 'green', label: '24', lines: {lineWidth: 2, dashPattern: [7,2]}},
                        {data: data[26][ellipse_ratio][previous_rp_answered], color: 'blue', label: '26', lines: {lineWidth: 2, dashPattern: [14,3]}},
                        {data: data[28][ellipse_ratio][previous_rp_answered], color: 'purple', label: '28', lines: {lineWidth: 2, dashPattern: [2,2]}},
                        {data: data[30][ellipse_ratio][previous_rp_answered], color: 'black', label: '30', lines: {lineWidth: 2, dashPattern: [3,4]}}
//                    {data: current_nodes1, color: 'red', points:{show:true, radius: 2}},
//                    {data: current_nodes2, color: 'green', points:{show:true, radius: 2, symbol: 'square'}},
//                    {data: current_nodes3, color: 'blue', points:{show:true, radius: 2, symbol: 'diamond'}}
                    ]

                    $.plot(id, graph_data, options)
                }
            }
        }
        plotted_total_graph = true
    }
}


var viewDistancesMi = function(data, rss_distances_data, limit_data, reader_powers, degrees) {
    var options = {
        legend: {show: true, position: 'ne'},
        yaxis: {min:0, max:500, ticks: 13},
        xaxis: {min:-85, max:-50, ticks: 10, tickDecimals: 0}
    }

    var divided_data = {}

    for(var reader_power_index in reader_powers) {
        var reader_power = reader_powers[reader_power_index]
        var limits = limit_data[reader_power]
        divided_data[reader_power] = {}
        for(var degree_index in degrees) {
            var degree = degrees[degree_index]

            divided_data[reader_power][degree] = {left:[], center:[], right:[]}
            for(var i in data[reader_power][degree]) {
                var value = data[reader_power][degree][i]
                if(value[0] >= limits[0] && value[0] <= limits[1]) {
                    divided_data[reader_power][degree]['center'].push(value)
                }
                else if(value[0] < limits[0]) {
                    divided_data[reader_power][degree]['left'].push(value)
                }
                else {
                    divided_data[reader_power][degree]['right'].push(value)
                }

            }
            var graph_data = [
                {data: divided_data[reader_power][degree]['center'], color: 'red', lines: {lineWidth: 2, dashPattern: [6,0]}, label: '20'},
                {data: divided_data[reader_power][degree]['left'], color: 'red', lines: {lineWidth: 2, dashPattern: [4,4]}},
                {data: divided_data[reader_power][degree]['right'], color: 'red', lines: {lineWidth: 2, dashPattern: [3,3]}},
                {data: rss_distances_data[reader_power], color: 'grey', points:{show:true, radius: 1}}
            ]
            var id = '#distances_mi_graph_' + reader_power + '_' + degree
            $.plot(id, graph_data, options)
        }
    }

    var power_groups = [[20,22,24], [26,28,30]]
    var colors = ['red', 'blue', 'black']
    var widths = [1, 2, 3]
    for(degree_index in degrees) {
        degree = degrees[degree_index]
        for(i = 0; i <= 1; i++) {
            id = '#distances_mi_graph_total_' + i + '_' + degree

            graph_data = []
            for(var power_i in power_groups[i]) {
                var power = power_groups[i][power_i]
                graph_data.push({data: divided_data[power][degree]['center'], color: colors[power_i], lines: {lineWidth: widths[power_i], dashPattern: [6,0]}, label: power})
                graph_data.push({data: divided_data[power][degree]['left'], color: colors[power_i], lines: {lineWidth: widths[power_i], dashPattern: [4,4]}})
                graph_data.push({data: divided_data[power][degree]['right'], color: colors[power_i], lines: {lineWidth: widths[power_i], dashPattern: [4,4]}})
            }
            $.plot(id, graph_data, options)
        }
    }

}


var rssRrCorrelation = function(correlation) {
    var options = {
        legend: {show: false},
        yaxis: {min:0, max:1.02, ticks: 11, tickDecimals: 1},
        xaxis: {min:20, max:30, ticks: 11, tickDecimals: 0}
    }
    var graph_data = [{data: correlation, color: 'red', lines: {lineWidth: 1}}]
    var id = '#rss_r_correlation'
    $.plot(id, graph_data, options)
}

var drawRssTimeGraph = function(data) {
    var yaxis = [-68, -59]
    var options = {
        legend: {show: false},
        yaxis: {min: yaxis[0], max: yaxis[1], ticks: 6, tickDecimals: 0},
        xaxis: {min:0, max:110, ticks: 12, tickDecimals: 0}
    }

    console.log(data)

    var tags_to_show = []
    var lines = [
        {pattern: [4,0], color: 'red'},
        {pattern: [3,2], color: 'green'},
        {pattern: [5,4], color: 'blue'},
        {pattern: [7,2], color: 'purple'},
        {pattern: [1,1], color: 'orange'}
    ]
    for(var reader_power = 20; reader_power <= 30; reader_power += 10) {
        if(reader_power == 20) {
            tags_to_show = ['AA28'] //28
        }
        else {
//            tags_to_show = ['AA01', 'AA10', 'AA17', 'AA28', 'AA36']
            tags_to_show = ['AA10']
        }


        var graph_data = []
        var histogram_data = []
        var raw_histogram_data = []
        var i = 0
        for(var tag_id in data[reader_power]) {
            if(tags_to_show.indexOf(tag_id) > -1) {
                raw_histogram_data[i] = []
                var raw_tag_data = data[reader_power][tag_id]
                var tag_data = raw_tag_data.map(function(x, i){
                    if(x != null)var response = [i, x]
                    return response
                }).filter(function(x){return x != undefined})
                graph_data.push({data: tag_data, color: lines[i].color, lines: {lineWidth: 1, dashPattern: lines[i].pattern}})

                var rss_count = 0
                raw_tag_data.filter(function(x){return x != undefined}).forEach(function(x){
                    if(raw_histogram_data[i][x] == undefined)raw_histogram_data[i][x] = 0
                    raw_histogram_data[i][x] += 1
                    rss_count += 1
                })


                var current_tag_histogram_data = []
                for(var rss in raw_histogram_data[i]) {
                    var rate_in_this_range = raw_histogram_data[i][rss] / rss_count
                    current_tag_histogram_data.push([parseInt(rss) - 0.5, 0])
                    current_tag_histogram_data.push([parseInt(rss) - 0.5, rate_in_this_range])
                    current_tag_histogram_data.push([parseInt(rss) + 0.5, rate_in_this_range])
                    current_tag_histogram_data.push([parseInt(rss) + 0.5, 0])
                }
                histogram_data.push({data: current_tag_histogram_data, color: lines[i].color, lines: {lineWidth: 1}})


                i += 1
            }
        }

        var id = '#rss_time_graph_' + reader_power.toString()
        $.plot(id, graph_data, options)

        $.plot('#rss_time_histogram_' + reader_power.toString(), histogram_data,
            {
                legend: {show: false},
                yaxis: {min:0, max:0.7, ticks: 11, tickDecimals: 1},
                xaxis: {min: yaxis[0], max: yaxis[1], ticks: 13, tickDecimals: 0}
            }
        )
    }
}



var plotDeploymentErrorsMaps = function(all_results) {
    var options = {
        legend: {show: false},
        yaxis: {min:0, max:500, ticks: 11, tickDecimals: 1},
        xaxis: {min:0, max:500, ticks: 11, tickDecimals: 1},
        grid: { hoverable: true, clickable: true, color: '#222222'}
    }
    var graph_data = [{data: {}, color: 'red', lines: {lineWidth: 1}}]


    for(var i in all_results) {
        var results = all_results[i]
        var antennae = results['antennae']
        var step = results['step']
        var errors = results['result']['data']
        var estimates = results['result']['estimates']

        var id = '#error_distribution_' + i
        var plot = $.plot(id, graph_data, options)
        var canvas = new Canvas(plot.getCanvas().getContext("2d"))
        var offset = plot.getPlotOffset()
        var scaling = {x: plot.getAxes().xaxis.scale, y: plot.getAxes().yaxis.scale}

        var extrema = {min:9999999999.9, max:0.0}
        for(var x = 0.0; x <= 500.0; x += step) {
            for(var y = 0.0; y <= 500.0; y += step) {
                if(errors[x] != undefined && errors[x][y] != undefined) {
                    var error = errors[x][y]
                    if(error > extrema['max'])
                        extrema['max'] = error
                    if(error < extrema['min'])
                        extrema['min'] = error
                }
            }
        }


        canvas.ctx.rect(offset.left, offset.top, 500*scaling.x, 500*scaling.y);
        canvas.ctx.stroke();
        canvas.ctx.clip()

        for(var antenna_number in antennae) {
            var canvas_coords = plot.p2c({
                x: antennae[antenna_number].coordinates.x,
                y: antennae[antenna_number].coordinates.y
            })
            var ellipse_rotation = - antennae[antenna_number].rotation * 180 / Math.PI
            var ellipse_cx = offset.left + canvas_coords.left
            var ellipse_cy = offset.top + canvas_coords.top
            var ellipse_width = antennae[antenna_number].coverage_zone_width * scaling.x
            var ellipse_height = antennae[antenna_number].coverage_zone_height * scaling.y
            var big_ellipse_width = antennae[antenna_number].big_coverage_zone_width * scaling.x
            var big_ellipse_height = antennae[antenna_number].big_coverage_zone_height * scaling.y

            canvas.drawRectangle(ellipse_cx, ellipse_cy, 3, 3, [0, 0, 255, 1.0])
            canvas.drawEllipse(ellipse_cx, ellipse_cy, ellipse_width/2, ellipse_height/2, ellipse_rotation, [255,255,255,0.0], '#000')
            canvas.drawEllipse(ellipse_cx, ellipse_cy, big_ellipse_width/2, big_ellipse_height/2, ellipse_rotation, [255,255,255,0.0], '#999')
            canvas.drawText(ellipse_cx + 10, ellipse_cy + 10, antenna_number, 24, [0,0,0,1.0])
        }



        for(x = 0.0; x <= 500.0; x += step) {
            for(y = 0.0; y <= 500.0; y += step) {
                var point = {x: x, y: y}
                if(errors[x] != undefined && errors[x][y] != undefined) {
                    error = errors[point.x][point.y]
                    drawRectangle(plot, error, point, step, false, extrema)
                }
                else {
                    drawRectangle(plot, null, point, step, false, extrema)
                }
            }
        }

        var saved_map = canvas.ctx.getImageData(offset.left, offset.top, 500*scaling.x, 500*scaling.y);
        setMapHoverHandler(i, id, step, plot, errors, extrema, estimates, saved_map)
    }
}


var setMapHoverHandler = function(method_name, div_id, step, plot, errors, extrema, all_estimates, saved_map) {
    function roundPosition(position) {
        return step * Math.round(position / step);
    }
    function writeErrorValueInDiv(error, rounded_position_string) {
        $("#data_" + method_name + " > div:nth-child(1) span:nth-child(2)").html(error)
        $("#data_" + method_name + " > div:nth-child(1) span:nth-child(4)").html(rounded_position_string)
    }

    var lastShown = [undefined, undefined]
    var canvas = new Canvas(plot.getCanvas().getContext("2d"))
    var offset = plot.getPlotOffset()
    var scaling = {x: plot.getAxes().xaxis.scale, y: plot.getAxes().yaxis.scale}

    var points_to_color_back = []
    $(div_id).bind("mouseout", function (e) {
        canvas.ctx.putImageData(saved_map, offset.left, offset.top);
    })
    $(div_id).bind("mousemove", function (e) {
        var position = [
            (e.pageX-$(this).position().left-offset.left)/scaling.x,
            500 - (e.pageY-$(this).position().top-offset.top)/scaling.y
        ]
        var rounded_position = [roundPosition(position[0]), roundPosition(position[1])]
        var rounded_position_string = "(" + rounded_position[0] + ", " + rounded_position[1] + ")"
        if(errors[rounded_position[0]] != undefined) {
            var error = errors[rounded_position[0]][rounded_position[1]]
            if(error != undefined) {
                if(lastShown[0] != rounded_position[0] || lastShown[1] != rounded_position[1]) {
                    var indices_to_delete = []
                    for(var i in points_to_color_back) {
                        var point = points_to_color_back[i]
                        var estimate_error = errors[point.x][point.y]
                        drawRectangle(plot, estimate_error, point, step, true, extrema)
                        indices_to_delete.push(i)
                    }
                    for(i in indices_to_delete) {
                        points_to_color_back.splice(indices_to_delete[i])
                    }

                    $(".map_hover_tip").remove();
                    lastShown = rounded_position
                    writeErrorValueInDiv(error.toFixed(2), rounded_position_string)

                    if(all_estimates != undefined) {
                        var estimates = all_estimates[rounded_position[0]][rounded_position[1]]
                        $("#data_" + method_name + " > div:nth-child(4) span").html(JSON.stringify(estimates))
                        for(i in estimates) {
                            if(estimates[i][0] != null) {
                                var estimate = {x: estimates[i][0].x, y: estimates[i][0].y}
                                var rounded_estimate = {x: roundPosition(estimate.x), y: roundPosition(estimate.y)}
                                var canvas_coords = plot.p2c(rounded_estimate)
                                canvas.drawRectangle(offset.left + canvas_coords.left,
                                    offset.top + canvas_coords.top,
                                    scaling.x * step,
                                    scaling.y * step,
                                    [255, 0, 0, 0.7])
                                showMapHoverTip(
                                    div_id,
                                    [canvas_coords.left, canvas_coords.top],
                                    (estimates[i][1]*100)+'%'
                                )
                                if(points_to_color_back.indexOf(rounded_estimate) == -1) {
                                    points_to_color_back.push(rounded_estimate)
                                }
                            }
                        }
                    }
                }
            }
            else {
                writeErrorValueInDiv('_', rounded_position_string)
                $("#data_" + method_name + " > div:nth-child(4) span").html('')
            }
        }
        else {
            writeErrorValueInDiv('_', rounded_position_string)
            $("#data_" + method_name + " > div:nth-child(4) span").html('')
        }
    })
    $(div_id).bind("mouseout", function (e) {
        $(".map_hover_tip").remove()
    })
}

var showMapHoverTip = function(append_to, position, contents) {
    var object = $("<div class='map_hover_tip'>" + contents + "</div>").css({
        position: "absolute",
        display: "none",
        top: position[1] + 15,
        left: position[0] + 55,
        border: "1px solid #fdd",
        padding: "2px",
        "background-color": "#fee",
        opacity: 0.80
    })
    object.appendTo(append_to).show()
}

var drawRectangle = function(plot, error, point, step, rewhite, extrema) {
    var canvas = new Canvas(plot.getCanvas().getContext("2d"))
    var offset = plot.getPlotOffset()
    var scaling = {x: plot.getAxes().xaxis.scale, y: plot.getAxes().yaxis.scale}

    if(error != null) {
        var color = 255 - Math.round(200 * (error - extrema['min']) / (extrema['max'] - extrema['min']))
    }
    else {
        color = 0
    }

    var canvas_coords = plot.p2c({x: point.x, y: point.y})
    if(rewhite) {
        canvas.drawRectangle(
            offset.left + canvas_coords.left,
            offset.top + canvas_coords.top,
            scaling.x * step,
            scaling.y * step,
            [255, 255, 255, 1.0]
        )
    }
    canvas.drawRectangle(
        offset.left + canvas_coords.left,
        offset.top + canvas_coords.top,
        scaling.x * step,
        scaling.y * step,
        [color, color, color, 0.7]
    )
}