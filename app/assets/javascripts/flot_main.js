var algorithms = {}
var work_zone = {}
var trilateration_map_data = {}



function startMainPlotting() {
    var flotDrawer = new FlotDrawer(algorithms, work_zone, trilateration_map_data)

    if ($('#cdf_div').length) flotDrawer.distribution_function.plotCdf('#cdf_div')
    if ($('#pdf_div').length) flotDrawer.distribution_function.plotPdf('#pdf_div')
    flotDrawer.plotMaps(getHeightsMapSelectArray())

    createHandlersForMaps()



    $('#pdf_div').click(function() {
        flotDrawer.distribution_function.changePdfState('#pdf_div')
    })




    $('#algorithm_heights_to_map_select').change(function() {
        flotDrawer.plotMaps(getHeightsMapSelectArray())
        if($('#comparing_algorithms_map').is(':visible')) compareAlgorithms()
    })

    $('#joint_estimates_show_button').click(function() {
        var tag_index = getTagIndexFromTextField('joint_estimates_input')
        if (getAlgorithmWithTag(tag_index)) {
            $('#joint_estimates_map').show()
            flotDrawer.drawJointEstimatesMap(tag_index)
            flotDrawer.showJointEstimatesMi(tag_index)
        }
    })

    $('#trilateration_show_button').click(function() {
        var tag_index = getTagIndexFromTextField('trilateration_input')
        if(trilateration_map_data['data'][tag_index] != undefined) {
            var algorithm_with_tag = getAlgorithmWithTag(tag_index)
            if(algorithm_with_tag) {
                var tag_position = algorithms[algorithm_with_tag]['map'][tag_index]['position']
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
            flotDrawer.drawComparingMap(algorithms_to_compare, getHeightsMapSelectArray())
        }
    }





    function getHeightsMapSelectArray() {
        var heights = {}
        var heights_ary = $('#algorithm_heights_to_map_select').val().split('-')
        heights.train = heights_ary[0] - 1
        heights.test = heights_ary[1] - 1
        return heights
    }


    function createHandlersForMaps() {
        for(var algorithm_name in algorithms) {
            var map_div_id = '#' + algorithm_name + '_map'
            $(map_div_id).click(function() {
                var div_id = $(this).attr("id")
                var algorithm_name = div_id.split("_").slice(0, -1).join("_")
                flotDrawer.changeMapState(algorithm_name, getHeightsMapSelectArray())
            })
        }
    }

    function getAlgorithmWithTag(tag_index) {
        for(var algorithm_name in algorithms)
            if (algorithms[algorithm_name]['map'][tag_index] != undefined)
                return algorithm_name
        return false
    }


    function getTagIndexFromTextField(text_field_id) {
        var tag_index = $('#' + text_field_id).val().toUpperCase()
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

}