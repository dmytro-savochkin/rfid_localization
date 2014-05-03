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
            $(map_div_id).click(function() {
                var div_id = $(this).attr("id")
                var algorithm_name = div_id.split("_").slice(0, -1).join("_")
                flotDrawer.changeMapState(algorithm_name)
            })
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
                    var axis_height = 400

                    for(var j = 0; j < steps; j++) {
                        var count_in_this_range = deviations[ellipse_ratio][max_degree][reader_power].filter(function(x){
                            return (x >= current_shift && x < (current_shift + step_size))
                        }).length

                        if(count_in_this_range > axis_height) {
                            axis_height = Math.ceil(count_in_this_range / 100) * 100
                        }

                        data.push([current_shift, 0])
                        data.push([current_shift, count_in_this_range])
                        data.push([current_shift + step_size, count_in_this_range])
                        data.push([current_shift + step_size, 0])
                        current_shift += step_size
                    }

                    var j = 0
                    var graph_data = [
                        {data: data, color: 'red', label: 'x'}
                    ]
                    var options = {
                        yaxis: {min:0, max:axis_height, ticks: 10},
                        xaxis: {min:-axis_width, max:axis_width, ticks: 20, tickDecimals: 0}
                    }

                    $.plot(id, graph_data, options)
                }
            }
        }
    }
}

var regressionProbabilitiesDistances = function(data, nodes, reader_powers, ellipse_ratios) {
    for(var reader_power_index in reader_powers) {
        var reader_power = reader_powers[reader_power_index]
        for(var ellipse_ratio_index in ellipse_ratios) {
            var ellipse_ratio = ellipse_ratios[ellipse_ratio_index].toFixed(1)
            var current_nodes = []
            var current_nodes2 = []
            var current_nodes3 = []
            for(var node_i in nodes[reader_power][ellipse_ratio]) {
                current_nodes.push([node_i, nodes[reader_power][ellipse_ratio][node_i]])
            }
            for(var node_i in nodes[25][ellipse_ratio]) {
                current_nodes2.push([node_i, nodes[25][ellipse_ratio][node_i]])
            }
            for(var node_i in nodes[30][ellipse_ratio]) {
                current_nodes3.push([node_i, nodes[30][ellipse_ratio][node_i]])
            }
            var current_data = data[reader_power][ellipse_ratio]
            var graph_data = [
                {data: current_data, color: 'red', label: '20', lines: {lineWidth: 2, dashPattern: [7,0]}},
//                {data: data[25][ellipse_ratio], color: 'green', label: '25', lines: {lineWidth: 2, dashPattern: [7,2]}},
//                {data: data[30][ellipse_ratio], color: 'blue', label: '30', lines: {lineWidth: 2, dashPattern: [14,3]}},
//                {data: current_nodes, color: 'red', points:{show:true, radius: 2}},
//                {data: current_nodes2, color: 'green', points:{show:true, radius: 2, symbol: 'square'}},
//                {data: current_nodes3, color: 'blue', points:{show:true, radius: 2, symbol: 'diamond'}}
            ]
            var id = '#probabilities_graph_' + reader_power + '_' + ellipse_ratio.replace(/\./, '')
            var options = {
                yaxis: {min:0, max:1.1, ticks: 11},
                xaxis: {min:0, max:700, ticks: 20, tickDecimals: 0}
            }
            $.plot(id, graph_data, options)
        }
    }
}


var viewDistancesMi = function(data, limit_data, reader_powers, degrees) {
    for(var reader_power_index in reader_powers) {
        var reader_power = reader_powers[reader_power_index]
        var limits = limit_data[reader_power]
        for(var degree_index in degrees) {
            var degree = degrees[degree_index]

            var divided_data = {left:[], center:[], right:[]}
                for(var i in data[reader_power][degree]) {
                    var value = data[reader_power][degree][i]
                    if(value[0] >= limits[0] && value[0] <= limits[1]) {
                        divided_data['center'].push(value)
                    }
                    else if(value[0] < limits[0]) {
                        divided_data['left'].push(value)
                    }
                    else {
                        divided_data['right'].push(value)
                    }

                }


            var graph_data = [
                {data: divided_data['center'], color: 'red', lines: {lineWidth: 2, dashPattern: [6,0]}, label: '20'},
                {data: divided_data['left'], color: 'red', lines: {lineWidth: 2, dashPattern: [4,4]}},
                {data: divided_data['right'], color: 'red', lines: {lineWidth: 2, dashPattern: [3,3]}},

//                {data: divided_data[25]['center'], color: 'green', lines: {lineWidth: 3, dashPattern: [6,0]}, label: '25'},
//                {data: divided_data[25]['left'], color: 'green', lines: {lineWidth: 3, dashPattern: [4,4]}},
//                {data: divided_data[25]['right'], color: 'green', lines: {lineWidth: 3, dashPattern: [3,3]}},
//
//                {data: divided_data[30]['center'], color: 'blue', lines: {lineWidth: 4, dashPattern: [6,0]}, label: '30'},
//                {data: divided_data[30]['left'], color: 'blue', lines: {lineWidth: 4, dashPattern: [4,4]}},
//                {data: divided_data[30]['right'], color: 'blue', lines: {lineWidth: 4, dashPattern: [3,3]}},
//                {data: data[23][degree], color: 'green', lines: {lineWidth: 2, dashPattern: [2,2]}, label: '23'},
//                {data: data[25][degree], color: 'black', lines: {lineWidth: 1, dashPattern: [6,6]}, label: '25'},
//                {data: data[27][degree], color: 'purple', lines: {lineWidth: 3, dashPattern: [6,0]}, label: '27'},
//                {data: data[30][degree], color: 'yellow', lines: {lineWidth: 2, dashPattern: [15,2]}, label: '30'},
//                {data: limits[0], color: 'red', lines: {lineWidth: 0.25, dashPattern: [5,4]}},
//                {data: limits[1], color: 'red', lines: {lineWidth: 0.25, dashPattern: [5,4]}}
            ]
            var id = '#distances_mi_graph_' + reader_power + '_' + degree

            var options = {
                legend: {show: true, position: 'ne'},
                yaxis: {min:0, max:400, ticks: 11},
                xaxis: {min:-85, max:-50, ticks: 10, tickDecimals: 0}
            }
            $.plot(id, graph_data, options)
        }
    }
}