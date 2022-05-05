// TODO: export from WASM?
const WEFX_KEYDOWN = 0;
const WEFX_KEYPRESS = 1;
const WEFX_KEYUP = 2;
const WEFX_MOUSEMOVE = 3;
const WEFX_MOUSEDOWN = 4;
const WEFX_MOUSEUP = 5;
const WEFX_CLICK = 6;

const PIXEL_SIZE = 4; // TODO

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

    // Exported functions defined by the user
    const init = instance.exports.init;
    const main_loop = instance.exports.main_loop;

    // Exported functions defined by the wefx library
    const wefx_xsize = instance.exports.wefx_xsize;
    const wefx_ysize = instance.exports.wefx_ysize;
    const wefx_screen_offset = instance.exports.wefx_screen_offset;
    const wefx_flush = instance.exports.wefx_flush;
    // const wefx_add_queue_event = instance.exports.wefx_add_queue_event;

    // The user-defined init() function returns a pointer to a WEFX instance
    const wefx_ptr = init();
    if (wefx_ptr == null) {
        console.error("Initialization failed");
        return;
    }

    // Both the width and the height of the screen are defined in the wasm module
    const width = wefx_xsize(wefx_ptr);
    const height = wefx_ysize(wefx_ptr);
    canvas.width = width;
    canvas.height = height;

    // wefx_screen_offset returns the offset in the memory where the array of pixels starts
    const offset = wefx_screen_offset(wefx_ptr);
    const imgArray = new Uint8ClampedArray(memory.buffer, offset, PIXEL_SIZE * width * height);
    const image = new ImageData(imgArray, width);

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
    const loop = (t) => {
        const current = Date.now();
        const delta = current - start;

        main_loop(delta * 0.05);
        wefx_flush(wefx_ptr);

        ctx.putImageData(image, 0, 0);

        requestAnimationFrame(loop);
    };
    requestAnimationFrame(loop);
}

bootstrap();
