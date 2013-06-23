function drawEllipse(ctx, x, y, a, b, angle_degrees, color) {
    var scaling = b/a;

    var angle_radianes = angle_degrees * Math.PI/180;

    function calc_translation_shifts(x, y, angle) {
        var hypotenuse = Math.sqrt(x*x+y*y);
        var beta = Math.atan(y/x);
        var alpha = (angle - beta);
        var y_shift = hypotenuse * Math.sin(-alpha);
        var x_shift = hypotenuse * Math.cos(alpha);
        return {x: x_shift, y: y_shift};
    }


    ctx.beginPath();
    ctx.save();

    ctx.rotate(angle_radianes);

    var shifts = calc_translation_shifts(x, y, angle_radianes);
    ctx.translate(shifts.x,shifts.y);

    ctx.scale(1, scaling);
    ctx.arc(0, 0, a, 0 , 2 * Math.PI, false);
    ctx.fillStyle = "rgba("+color[0]+", "+color[1]+", "+color[2]+", "+color[3]+")";
    ctx.fill();
    ctx.lineWidth = 1;
    ctx.stroke();

    ctx.restore();
    ctx.closePath();
}

function drawText(ctx, x, y, text, size) {
    ctx.beginPath();
    ctx.font=size + 'px Arial';
    ctx.fillStyle='#000000';
    ctx.fillText(text, x, y);

    ctx.closePath();
}