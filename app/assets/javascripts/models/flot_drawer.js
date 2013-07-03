function FlotDrawer(algorithms, measurement_information, trilateration_map_data) {
    this.mapChartOptions = {
        legend: {show: false},
        yaxis: {min:0, max:505, ticks: 10},
        xaxis: {min:0, max:505, ticks: 10},
        series: {
            points: {show: true, radius: 5}
        },
        grid: {hoverable: true, clickable: true}
    }

    this.algorithms = algorithms
    this.measurement_information = measurement_information
    this.trilateration_map_data = trilateration_map_data

    this.distribution_function = new DistributionFunction(this.algorithms)

    this.maps_states = ['distances', 'errors']
    this.maps_current_states = {}

    this.map_elements = {
        comparing_ls_js: {
            map: '#comparing_ls_js_map'
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
    $(this.map_elements.trilateration.mi).append('<br><strong>Distances</strong><br>')
    for(var i in mi['distances'])
        $(this.map_elements.trilateration.mi).append(i + ': ' +mi['distances'][i] + '<br>')



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
}





flotDrawerProto.drawJointEstimatesMap = function(tag_id) {
    var div_id = this.map_elements.joint_estimates.map

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

    for(var algorithm_name in this.algorithms) {
        if(data[0]['data'] == undefined)
            data[0]['data'] = [[
                this.algorithms[algorithm_name]['map'][tag_id]['position']['x'],
                this.algorithms[algorithm_name]['map'][tag_id]['position']['y']
            ]]
        data.push({
            name: algorithm_name,
            data: [[
                this.algorithms[algorithm_name]['map'][tag_id]['estimate']['x'],
                this.algorithms[algorithm_name]['map'][tag_id]['estimate']['y']
            ]],
            color: "rgba(0, 0, 200, 0.5)",
            lines: {show: false},
            points: {symbol: "cross",show: true, radius: 10, fill: true}
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

    for(var antenna_number in antennae_hash) {
        var canvas_coords = plot.p2c({
            x: antennae_hash[antenna_number].data[0][0],
            y: antennae_hash[antenna_number].data[0][1]
        })

        var ellipse_cx = offset.left + canvas_coords.left
        var ellipse_cy = offset.top + canvas_coords.top
        var ellipse_width = antennae_hash[antenna_number].coverage_sizes[0] * scaling.x
        var ellipse_height = antennae_hash[antenna_number].coverage_sizes[1] * scaling.y

        canvas.drawEllipse(ellipse_cx, ellipse_cy, ellipse_width, ellipse_height, -45, [200,0,0,0.1])
        canvas.drawText(ellipse_cx + 10, ellipse_cy + 10, antennae_hash[antenna_number].name, 24, [0,0,0,1.0])
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
        var reader_power = this.algorithms[algorithm_name]['work_zone']['reader_power']
        if(jQuery.inArray(reader_power, shown_reader_powers) == -1) {
            if(added >= 2) {
                td = $("<td>", {class: "td_mi"})
                tr.append(td)
                added = 0
            }

            shown_reader_powers.push(reader_power)
            var answers = this.algorithms[algorithm_name]['tags'][tag_index]['answers']

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




flotDrawerProto.drawComparingLsJsMap = function(algorithms) {
    var tag_step = 40

    var plot = $.plot(this.map_elements.comparing_ls_js.map, [{}], this.mapChartOptions)

    var canvas = new Canvas(plot.getCanvas().getContext("2d"))
    var offset = plot.getPlotOffset()
    var scaling = {x: plot.getAxes().xaxis.scale, y: plot.getAxes().yaxis.scale}

    var max = 0.0
    for(var tag_name in algorithms[0].map) {
        var difference = Math.abs(
            algorithms[0].map[tag_name].error - algorithms[1].map[tag_name].error
        )
        if(difference > max)max = difference
    }

    for(var tag_name in algorithms[0].map) {
        var error = algorithms[0].map[tag_name].error - algorithms[1].map[tag_name].error
        var position = algorithms[0].map[tag_name].position
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
        var div_id = '#' + algorithm_name + '_map'
        this.maps_current_states[algorithm_name] = {state: this.maps_states[0], plot: undefined}
        this.plotMap(algorithm_name, this.maps_current_states[algorithm_name].state)
        this.setMapHoverHandler(div_id, 'name')
    }
}

flotDrawerProto.plotMap = function(algorithm_name, state) {
    var flot_data = this['plot' + state.capitalize() + 'Map'](algorithm_name)
    var div_id = '#' + algorithm_name + '_map'
    if(flot_data) {
        this.maps_current_states[algorithm_name].plot = $.plot( div_id, flot_data, this.mapChartOptions)
    }
}

flotDrawerProto.changeMapState = function(algorithm_name) {
    var state = this.maps_current_states[algorithm_name].state
    var new_state = undefined
    for(var i = 0; i < this.maps_states.length; i += 1) {
        if(state == this.maps_states[i]) {
            if(i >= (this.maps_states.length - 1))new_state = this.maps_states[0]
            else new_state = this.maps_states[i + 1]
            break
        }
    }
    this.maps_current_states[algorithm_name].state = new_state
    this.plotMap(algorithm_name, new_state)
}



flotDrawerProto.plotDistancesMap = function(algorithm_name) {
    var input_data = this.algorithms[algorithm_name]['map']

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
            points: { symbol: "cross", fill: true, fillColor: "rgba(0, 0, 255, 0.4)", radius: 7}
        }
    ]

    var antennae_hash = this.createAntennaeFlotHash()
    for(var antenna_number in antennae_hash) {
        flot_data.push(antennae_hash[antenna_number])
    }

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
        for(var tag_name in this.algorithms[cycled_algorithm_name].map) {
            var cycled_error = this.algorithms[cycled_algorithm_name].map[tag_name].error
            if(cycled_error > max)max = cycled_error
        }
    }


    for(tag_name in this.algorithms[algorithm_name].map) {
        var error = this.algorithms[algorithm_name].map[tag_name].error
        var position = this.algorithms[algorithm_name].map[tag_name].position
        var color = [Math.round(255 * error / max), 0, 0, 0.9]
        var canvas_coords = this.maps_current_states[algorithm_name].plot.p2c({x: position.x, y: position.y})

        canvas.drawRectangle(
            offset.left + canvas_coords.left,
            offset.top + canvas_coords.top,
            scaling.x * tag_step,
            scaling.y * tag_step,
            color
        )
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
    for(var antenna_number in this.measurement_information['work_zone']['antennae']) {
        var antenna = this.measurement_information['work_zone']['antennae'][antenna_number]

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