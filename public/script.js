// TODO: export from WASM?
const WEFX_KEYDOWN = 0;
const WEFX_KEYPRESS = 1;
const WEFX_KEYUP = 2;
const WEFX_MOUSEMOVE = 3;
const WEFX_MOUSEDOWN = 4;
const WEFX_MOUSEUP = 5;
const WEFX_CLICK = 6;

const SIZE_OF_INT = 4; // TODO

const canvas = document.getElementById("screenCanvas");
const ctx = canvas.getContext("2d");
ctx.imageSmoothingEnabled = false;

function relativeXY(e, canvas) {
    const rect = canvas.getBoundingClientRect();
    return {
        x: (e.clientX - rect.left) | 0,
        y: (e.clientY - rect.top) | 0,
    };
}

async function bootstrap() {
    const { instance } = await WebAssembly.instantiateStreaming(fetch("./wefx.wasm"));

    const memory = instance.exports.memory;

    const init = instance.exports.init;
    const main_loop = instance.exports.main_loop;

    const wefx_screen_offset = instance.exports.wefx_screen_offset;
    const wefx_draw = instance.exports.wefx_draw;
    const wefx_width = instance.exports.wefx_width;
    const wefx_height = instance.exports.wefx_height;
    // const wefx_add_queue_event = instance.exports.wefx_add_queue_event;

    const err = init();
    if (err) {
        console.error("Initialization failed");
        return;
    }

    const width = wefx_width();
    const height = wefx_height();
    canvas.width = width;
    canvas.height = height;

    const offset = wefx_screen_offset();
    const imgArray = new Uint8ClampedArray(memory.buffer, offset, SIZE_OF_INT * width * height);

    // const toWefxEvent = (t, e, canvas) => {
    //     const xy = relativeXY(e, canvas);
    //     const k = e.key ? e.key.charCodeAt(0) : 0;
    //     wefx_add_queue_event(t, e.button, e.timeStamp, k, xy.x, xy.y);
    // };

    // document.addEventListener("keypress", (e) => toWefxEvent(WEFX_KEYPRESS, e, canvas));
    // document.addEventListener("keydown", (e) => toWefxEvent(WEFX_KEYDOWN, e, canvas));
    // document.addEventListener("keyup", (e) => toWefxEvent(WEFX_KEYUP, e, canvas));
    // canvas.addEventListener("mousedown", (e) => toWefxEvent(WEFX_MOUSEDOWN, e, canvas));
    // canvas.addEventListener("mouseup", (e) => toWefxEvent(WEFX_MOUSEUP, e, canvas));
    // canvas.addEventListener("mousemove", (e) => toWefxEvent(WEFX_MOUSEMOVE, e, canvas));

    let start = Date.now();
    const image = new ImageData(imgArray, width);

    const loop = (t) => {
        const current = Date.now();
        const delta = current - start;

        main_loop(delta * 0.05);
        wefx_draw(offset);

        ctx.putImageData(image, 0, 0);

        requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
}

bootstrap();
