function FlotDrawer(algorithms, work_zone, trilateration_map_data) {
    this.mapChartOptions = {
        legend: {show: false},
        yaxis: {min:0, max:505, ticks: 10},
        xaxis: {min:0, max:505, ticks: 10},
        series: {
            points: {show: true, radius: 5}
        },
//        grid: false
        grid: {hoverable: true, clickable: true}
    }


    this.heights = undefined

    this.algorithms = algorithms
    this.work_zone = work_zone
    this.trilateration_map_data = trilateration_map_data

    this.distribution_function = new DistributionFunction(this.algorithms)

    this.maps_states = ['distances', 'errors', 'setup', 'train']
    this.maps_current_states = {}

    this.map_elements = {
        comparing_algorithms: {
            map: '#comparing_algorithms_map'
        },
        joint_estimates: {
            map: '#joint_estimates_map',
            mi: '#joint_estimates_mi'
        },
        trilateration: {
            map: '#trilateration_map',
            mi: '#trilateration_mi'
        }
    }
}
var flotDrawerProto = FlotDrawer.prototype






flotDrawerProto.updateHeights = function(heights) {
    this.heights = heights
    this.distribution_function.heights = heights
}






flotDrawerProto.updateSuitabilityTable = function() {
    if(document.getElementById('suitability_table')) {
        var values = []
        for(var antenna_count = 1; antenna_count <= 16; antenna_count += 1) {
            values.push(antenna_count)
        }
        values.push('all')

        for(var algorithm_name in this.algorithms) {
            for(var i in values) {
                var a = values[i]
                var cell = $('#suitability_table tr.' + algorithm_name + ' td.' + a)
                var best_suited = this.
                    algorithms[algorithm_name]['best_suited'][this.heights][a]
                cell.html(best_suited)
            }
        }
    }
}


flotDrawerProto.drawTrilaterationColorMap = function(tag_position, tag_index) {
    var extremum_criterion = this.trilateration_map_data['extremum_criterion']
    var mi = this.trilateration_map_data['mi'][tag_index]
    var map = this.trilateration_map_data['data'][tag_index]


    $(this.map_elements.trilateration.mi).html('<strong>MI</strong><br>')
    for(var i in mi['mi'])
        $(this.map_elements.trilateration.mi).append(i + ': ' +mi['mi'][i] + '<br>')
    $(this.map_elements.trilateration.mi).append('<br><strong>Filtered MI</strong><br>')
    for(var i in mi['filtered'])
        $(this.map_elements.trilateration.mi).append(i + ': ' +mi['filtered'][i] + '<br>')



    var step = Object.keys(map)[1] - Object.keys(map)[0]
    var extremum = undefined
    for(var x in map) {
        for(var y in map[x]) {
            if(extremum_criterion == 'min')
                if(extremum == undefined || map[x][y] < extremum)
                    extremum = map[x][y]
            if(extremum_criterion == 'max')
                if(extremum == undefined || map[x][y] > extremum)
                    extremum = map[x][y]
        }
    }


    var data = [{
        data: [[tag_position['x'], tag_position['y']]],
        points: {
            symbol: "circle",
            fill: true,
            radius: 10,
            fillColor: "rgba(0, 255, 0, 1)"
        }
    }]
    var plot = $.plot(this.map_elements.trilateration.map, data, this.mapChartOptions)

    var ctx = plot.getCanvas().getContext("2d")
    var canvas = new Canvas(ctx)
    var offset = plot.getPlotOffset()
    var scaling = {x: plot.getAxes().xaxis.scale, y: plot.getAxes().yaxis.scale}

    for(var x in map) {
        for(var y in map[x]) {
            var ratio = 0.0
            if(extremum_criterion == 'min')ratio = extremum / map[x][y]
            if(extremum_criterion == 'max')ratio = map[x][y] / extremum

            var color = [Math.round(255 * ratio), 0, 0, 0.9]
            if(extremum == map[x][y])color = [0, 255, 0, 0.9]
            var canvas_coords = plot.p2c({x: x, y: y})

            canvas.drawRectangle(
                offset.left + canvas_coords.left,
                offset.top + canvas_coords.top,
                scaling.x * step,
                scaling.y * step,
                color
            )
        }
    }



    function roundPosition(position) {
        return step * Math.round(position / step);
    }

    $(this.map_elements.trilateration.map).bind("mousemove", function (e) {
        var position = [
            (e.pageX-$(this).position().left-offset.left)/scaling.x,
            500 - (e.pageY-$(this).position().top-offset.top)/scaling.y
        ]
        if(position[1] < -100)position[1] += 628
        var rounded_position = [roundPosition(position[0]), roundPosition(position[1])]
        var rounded_position_string = "(" + rounded_position[0] + ", " + rounded_position[1] + ")"

        if(map[rounded_position[0]] != undefined && map[rounded_position[0]][rounded_position[1]] != undefined) {
            $(".trilateration_data > span:nth-child(1)").html(JSON.stringify(map[rounded_position[0]][rounded_position[1]]))
            $(".trilateration_data > span:nth-child(2)").html(JSON.stringify(rounded_position_string))
        }
    })
}





flotDrawerProto.drawJointEstimatesMap = function(tag_id) {
    var div_id = this.map_elements.joint_estimates.map

    var data = [
        {
            name: 'true position',
            data: undefined,
            color: 'rgba(255, 0, 0, 0.4)',
            points: {
                symbol: "circle",
                fill: true,
                radius: 10,
                fillColor: "rgba(255, 0, 0, 0.4)"
            }
        }
    ]

    var colors = ['green', 'blue', 'purple', 'orange', 'black']
    var figures = ['cross', 'cross', 'cross', 'cross', 'circle']

    var zone_coords = []
    for(var algorithm_name in this.algorithms) {
        var color = colors[this.algorithms[algorithm_name]['group'] - 1]
        var figure = figures[this.algorithms[algorithm_name]['group'] - 1]
        var radius = 5
//        if(this.algorithms[algorithm_name]['combiner']) {
//            figure = 'circle'
//            color = 'black'
//            radius = 5
//        }

        if(data[0]['data'] == undefined) {
            data[0]['data'] = [[
                this.algorithms[algorithm_name]['map'][this.heights][tag_id]['position']['x'],
                this.algorithms[algorithm_name]['map'][this.heights][tag_id]['position']['y']
            ]]
            zone_coords[0] = this.algorithms[algorithm_name]['map'][this.heights][tag_id]['zone']['x']
            zone_coords[1] = this.algorithms[algorithm_name]['map'][this.heights][tag_id]['zone']['y']
        }

        data.push({
            name: algorithm_name,
            data: [[
                this.algorithms[algorithm_name]['map'][this.heights][tag_id]['estimate']['x'],
                this.algorithms[algorithm_name]['map'][this.heights][tag_id]['estimate']['y']
            ]],
            color: color,
            lines: {show: false},
            points: {symbol: figure, show: true, radius: radius, fill: false}
        })
    }

    var antennae_hash = this.createAntennaeFlotHash()
    for(var antenna_number in antennae_hash) {
        data.push(antennae_hash[antenna_number])
    }

    var plot = $.plot(div_id, data, this.mapChartOptions)
    this.setMapHoverHandler(div_id, 'name')
    var ctx = plot.getCanvas().getContext("2d");
    var canvas = new Canvas(ctx)

    var offset = plot.getPlotOffset()
    var scaling = {x: plot.getAxes().xaxis.scale, y: plot.getAxes().yaxis.scale}


//    var centroid_coords = [
//        this.algorithms['combo__0falsefalsefalsefalse10']['map'][this.heights][tag_id]['estimate']['x'],
//        this.algorithms['combo__0falsefalsefalsefalse10']['map'][this.heights][tag_id]['estimate']['y']
//    ]
//    var centroid_canvas_coords = plot.p2c({
//        x: centroid_coords[0],
//        y: centroid_coords[1]
//    })
//    var cc = [
//        offset.left + centroid_canvas_coords.left,
//        offset.top + centroid_canvas_coords.top
//    ]
//    canvas.drawCircle(cc[0], cc[1], 20, [100,100,100, 0.5])
//    canvas.drawCircle(cc[0], cc[1], 100, [100,100,100, 0.2])

    for(var antenna_number in antennae_hash) {
        var canvas_coords = plot.p2c({
            x: antennae_hash[antenna_number].data[0][0],
            y: antennae_hash[antenna_number].data[0][1]
        })

        var rotation_in_degrees = -antennae_hash[antenna_number].data[0][2] * 180.0 / Math.PI

        var ellipse_cx = offset.left + canvas_coords.left
        var ellipse_cy = offset.top + canvas_coords.top
        var ellipse_width = antennae_hash[antenna_number].coverage_sizes[0] * scaling.x
        var ellipse_height = antennae_hash[antenna_number].coverage_sizes[1] * scaling.y
        canvas.drawEllipse(ellipse_cx, ellipse_cy, ellipse_width/2, ellipse_height/2, rotation_in_degrees, [200,0,0,0.1], '#000')
        canvas.drawText(ellipse_cx + 10, ellipse_cy + 10, antennae_hash[antenna_number].name, 24, [0,0,0,1.0])
    }




    if(classifier != null && classifier.hasOwnProperty('probabilities')) {
        var zones_probabilities_object = classifier.probabilities[this.heights][tag_id]

        var zones_probabilities = Object.keys(zones_probabilities_object).map(function(key){return zones_probabilities_object[key];});
        var max_zones_probability = Math.max.apply(null, zones_probabilities);

        for(var zone_center in zones_probabilities_object) {
            var probability = zones_probabilities_object[zone_center]
            var zone_color = Math.floor(255 * (probability / max_zones_probability))

            var zone_center_array = zone_center.split('-')

            canvas_coords = plot.p2c({
                x: zone_center_array[0],
                y: zone_center_array[1]
            })

            if (zone_color != 0) {
                canvas.drawRectangle(
                    offset.left + canvas_coords.left,
                    offset.top + canvas_coords.top,
                    120 * scaling.x,
                    120 * scaling.y,
                    [zone_color, 0, 0, 0.2]
                )
            }
        }
    }
}



flotDrawerProto.showJointEstimatesMi = function(tag_index) {
    var shown_reader_powers = []
    var added = 0

    $(this.map_elements.joint_estimates.mi).html('<strong>' + tag_index + '</strong><br><br>')
    var table = $("<table>", {id: "table_mi"})
    $(this.map_elements.joint_estimates.mi).append(table)
    var tr = $("<tr>", {id: "tr_mi"})
    table.append(tr)
    var td = $("<td>", {class: "td_mi"})
    tr.append(td)

    for(var algorithm_name in this.algorithms) {
        var reader_power = this.algorithms[algorithm_name]['reader_power']
        if(jQuery.inArray(reader_power, shown_reader_powers) == -1 && reader_power != null) {
            if(added >= 2) {
                td = $("<td>", {class: "td_mi"})
                tr.append(td)
                added = 0
            }

            shown_reader_powers.push(reader_power)
            var answers = this.algorithms[algorithm_name]['tags_input'][this.heights]['test'][tag_index]['answers']

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

flotDrawerProto.showJointEstimatesData = function(tag_index) {
    var main_cell = $('#joint_estimates_estimates')
    main_cell.html('')
    var table = $("<table>", {id: "table_estimates"})
    main_cell.append(table)
    var tr = $("<tr>")
    var th1 = $("<th>")
    var th2 = $("<th>")
    var th3 = $("<th>")
    var th4 = $("<th>")
    tr.append(th1)
    tr.append(th2)
    tr.append(th3)
    tr.append(th4)
    th1.append('algorithm name')
    th2.append('estimate')
    th3.append('error')
    th4.append('probabilities')
    table.append(tr)

    for(var algorithm_name in this.algorithms) {
        tr = $("<tr>")
        table.append(tr)

        var td1 = $("<td>")
        var td2 = $("<td>")
        var td3 = $("<td>")
        var td4 = $("<td>")
        tr.append(td1)
        tr.append(td2)
        tr.append(td3)
        tr.append(td4)

        var estimate = this.algorithms[algorithm_name]['map'][this.heights][tag_index]['estimate']
        var error = this.algorithms[algorithm_name]['map'][this.heights][tag_index]['error']
        td1.append('<strong>' + algorithm_name + '</strong>:')
        td2.append(parseFloat(estimate['x']).toFixed(1) + '-' + parseFloat(estimate['y']).toFixed(1))
        td3.append(parseFloat(error).toFixed(1))

        if(this.algorithms[algorithm_name]['probabilities_with_zones_keys'] != undefined)
            td4.append(JSON.stringify(
                this.algorithms[algorithm_name]['probabilities_with_zones_keys'][this.heights][tag_index]
            ))
    }
}




flotDrawerProto.drawComparingMap = function(algorithms) {
    var tag_step = 40

    var plot = $.plot(this.map_elements.comparing_algorithms.map, [{}], this.mapChartOptions)

    var canvas = new Canvas(plot.getCanvas().getContext("2d"))
    var offset = plot.getPlotOffset()
    var scaling = {x: plot.getAxes().xaxis.scale, y: plot.getAxes().yaxis.scale}

    var max = 0.0
    for(var tag_name in algorithms[0].map[this.heights]) {
        var difference = Math.abs(
            algorithms[0].map[this.heights][tag_name].error -
                algorithms[1].map[this.heights][tag_name].error
        )
        if(difference > max)max = difference
    }

    for(var tag_name in algorithms[0].map[this.heights]) {
        var error = algorithms[0].map[this.heights][tag_name].error -
            algorithms[1].map[this.heights][tag_name].error
        var position = algorithms[0].map[this.heights][tag_name].position
        var color_value = Math.round(255 * Math.abs(error) / max)

        if(error < 0)var color = [color_value, 0, 0, 0.9]
        else if(error > 0)var color = [0, color_value, 0, 0.9]
        else var color = [0, 0, 0, 0.9]
        var canvas_coords = plot.p2c({x: position.x, y: position.y})

        canvas.drawRectangle(
            offset.left + canvas_coords.left,
            offset.top + canvas_coords.top,
            scaling.x * tag_step,
            scaling.y * tag_step,
            color
        )
        if(error != 0.0)
            canvas.drawText(
                offset.left + canvas_coords.left - 12,
                offset.top + canvas_coords.top + 5,
                Math.abs(error).toFixed(1),
                12,
                [255,255,255,1.0]
            )
    }


}

















flotDrawerProto.plotMaps = function() {
    for(var algorithm_name in this.algorithms) {
        var mean_error_id = '#' + algorithm_name + '_mean_error_field'
        var max_error_id = '#' + algorithm_name + '_max_error_field'
        if($(mean_error_id).length > 0) {
            $(mean_error_id).html(this.algorithms[algorithm_name]['errors_parameters'][this.heights]['total']['mean'])
        }
        if($(max_error_id).length > 0) {
            $(max_error_id).html(this.algorithms[algorithm_name]['errors_parameters'][this.heights]['total']['max'])
        }

        var div_id = '#' + algorithm_name + '_map'
        this.maps_current_states[algorithm_name] = {state: this.maps_states[0], plot: undefined}
        this.plotMap(algorithm_name, this.maps_current_states[algorithm_name].state)
        this.setMapHoverHandler(div_id, 'name')
    }
}

flotDrawerProto.plotMap = function(algorithm_name, state) {
    var flot_response = this['plot' + state.capitalize() + 'Map'](algorithm_name)
    var div_id = '#' + algorithm_name + '_map'

    if(flot_response) {
        this.maps_current_states[algorithm_name].plot = $.plot( div_id, flot_response, this.mapChartOptions)
    }
    $('#'+algorithm_name+'_map_type').html(state.capitalize())
}
flotDrawerProto.getCanvasContext = function(algorithm_name) {
    return new Canvas(this.maps_current_states[algorithm_name].plot.getCanvas().getContext("2d"))
}

flotDrawerProto.changeMapState = function(algorithm_name, forward) {
    var state = this.maps_current_states[algorithm_name].state
    var new_state = undefined
    for(var i = 0; i < this.maps_states.length; i += 1) {
        if(state == this.maps_states[i]) {
            if(i >= (this.maps_states.length - 1) && forward)
                new_state = this.maps_states[0]
            else if(i <= 0 && !forward)
                new_state = this.maps_states[this.maps_states.length - 1]
            else {
                if(forward)new_state = this.maps_states[i + 1]
                else new_state = this.maps_states[i - 1]
            }

            break
        }
    }
    this.maps_current_states[algorithm_name].state = new_state
    this.plotMap(algorithm_name, new_state)
}



flotDrawerProto.plotDistancesMap = function(algorithm_name) {
    var input_data = this.algorithms[algorithm_name]['map'][this.heights]

    var positions = []
    var estimates = []
    for(var tag_id in input_data) {
        positions.push( [input_data[tag_id]['position']['x'], input_data[tag_id]['position']['y']] )
        estimates.push( [input_data[tag_id]['estimate']['x'], input_data[tag_id]['estimate']['y']] )
    }

    var flot_data = [
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
            points: {symbol: "cross", fill: true, fillColor: "rgba(0, 0, 255, 0.4)", radius: 7}
        }
    ]

//    var antennae_hash = this.createAntennaeFlotHash()
//    for(var antenna_number in antennae_hash) {
//        flot_data.push(antennae_hash[antenna_number])
//    }

    for(tag_id in input_data) {
        flot_data.push(
            {
                name: tag_id,
                data: [
                    [input_data[tag_id]['position']['x'], input_data[tag_id]['position']['y']],
                    [input_data[tag_id]['estimate']['x'], input_data[tag_id]['estimate']['y']]
                ],
                color: "rgba(110, 110, 110, 0.1)",
                lines: {show: true},
                points: {show: false}
            }
        )
    }
    return flot_data
}
flotDrawerProto.plotSetupMap = function(algorithm_name) {
    var positions_data = this.algorithms[algorithm_name]['tags_input'][this.heights]['setup']
    var estimates_data = this.algorithms[algorithm_name]['setup'][this.heights]['estimates']

    var positions = []
    var estimates = []
    for(var tag_id in positions_data) {
        positions.push( [positions_data[tag_id]['position']['x'], positions_data[tag_id]['position']['y']] )
        estimates.push( [estimates_data[tag_id]['x'], estimates_data[tag_id]['y']] )
    }

    var flot_data = [
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
            points: {symbol: "cross", fill: true, fillColor: "rgba(0, 0, 255, 0.4)", radius: 7}
        }
    ]

    var antennae_hash = this.createAntennaeFlotHash()
    for(var antenna_number in antennae_hash) {
        flot_data.push(antennae_hash[antenna_number])
    }

    for(tag_id in positions_data) {
        flot_data.push(
            {
                name: tag_id,
                data: [
                    [positions_data[tag_id]['position']['x'], positions_data[tag_id]['position']['y']],
                    [estimates_data[tag_id]['x'], estimates_data[tag_id]['y']]
                ],
                color: "rgba(110, 110, 110, 0.1)",
                lines: {show: true},
                points: {show: false}
            }
        )
    }
    return flot_data
}
flotDrawerProto.plotTrainMap = function(algorithm_name) {
    var positions_data = this.algorithms[algorithm_name]['tags_input'][this.heights]['train']
    var positions = []
    for(var tag_id in positions_data) {
        positions.push( [positions_data[tag_id]['position']['x'], positions_data[tag_id]['position']['y']] )
    }
    var flot_data = [
        {
            label: 'positions',
            data: positions,
            color: 'rgba(255, 0, 0, 0.4)',
            points: {symbol: "square", fill: true, fillColor: "rgba(255, 0, 0, 0.4)"}
        }
    ]
    var antennae_hash = this.createAntennaeFlotHash()
    for(var antenna_number in antennae_hash) {
        flot_data.push(antennae_hash[antenna_number])
    }

    for(tag_id in positions_data) {
        var rss_list = JSON.stringify(positions_data[tag_id]['answers']['rss']['average'])
        var rr_list = JSON.stringify(positions_data[tag_id]['answers']['rr']['average'])
        flot_data.push(
            {
                name: rss_list + ' | ' + rr_list + ' | ',
                data: [
                    [positions_data[tag_id]['position']['x'], positions_data[tag_id]['position']['y']]
                ],
                color: "rgba(110, 110, 110, 0.1)",
                points: {show: false}
            }
        )
    }
    return flot_data
}
flotDrawerProto.plotErrorsMap = function(algorithm_name) {
    var tag_step = 40

    var canvas = new Canvas(this.maps_current_states[algorithm_name].plot.getCanvas().getContext("2d"))
    var offset = this.maps_current_states[algorithm_name].plot.getPlotOffset()
    var scaling = {
        x: this.maps_current_states[algorithm_name].plot.getAxes().xaxis.scale,
        y: this.maps_current_states[algorithm_name].plot.getAxes().yaxis.scale
    }

    var max = 0.0
    for(var cycled_algorithm_name in this.algorithms) {
        for(var tag_name in this.algorithms[cycled_algorithm_name].map[this.heights]) {
            var cycled_error = this.algorithms[cycled_algorithm_name].map[this.heights][tag_name].error
            if(cycled_error > max)max = cycled_error
        }
    }


    for(tag_name in this.algorithms[algorithm_name].map[this.heights]) {
        var error = this.algorithms[algorithm_name].map[this.heights][tag_name].error
        var position = this.algorithms[algorithm_name].map[this.heights][tag_name].position
        var color = [Math.round(255 * error / max), 0, 0, 0.9]
        var canvas_coords = this.maps_current_states[algorithm_name].plot.p2c({x: position.x, y: position.y})

        canvas.drawRectangle(
            offset.left + canvas_coords.left,
            offset.top + canvas_coords.top,
            scaling.x * tag_step,
            scaling.y * tag_step,
            color
        )
        if(error != null)
            canvas.drawText(
                offset.left + canvas_coords.left - 12,
                offset.top + canvas_coords.top + 5,
                error.toFixed(1),
                12,
                [255,255,255,1.0]
            )
    }

    return undefined
}






















flotDrawerProto.plotKGraph = function(data, id) {
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





















flotDrawerProto.setMapHoverHandler = function(div_id, field_to_show) {
    var previousPoint = null;
    var self = this
    $(div_id).bind("plothover", function (event, pos, item) {
        if (item) {
            if (previousPoint != item.dataIndex) {
                previousPoint = item.dataIndex;
                $(".map_hover_tip").remove();
                var x = item.datapoint[0].toFixed(1),
                    y = item.datapoint[1].toFixed(1);

                self.showMapHoverTip(
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

flotDrawerProto.showMapHoverTip = function(x, y, contents) {
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

flotDrawerProto.createAntennaeFlotHash = function() {
    var antennae_hash = []
    for(var antenna_number in this.work_zone['antennae']) {
        var antenna = this.work_zone['antennae'][antenna_number]

        antennae_hash.push(
            {
                name: antenna_number,
                coverage_sizes: [antenna.coverage_zone_width, antenna.coverage_zone_height],
                data: [
                    [antenna.coordinates.x, antenna.coordinates.y, antenna.rotation]
                ],
                color: "rgba(110, 110, 110, 0.1)",
                lines: {show: false},
                points: {show: true, radius: 10, symbol: 'square', fill: true, fillColor: "rgba(0, 255, 0, 0.4)"}
            }
        )
    }
    return antennae_hash
}