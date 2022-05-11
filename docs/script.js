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

function getWASMGlobalValue(memory, global) {
    const memory_array = new Uint8Array(memory.buffer);
    const global_offset = global.value;
    return memory_array[global_offset];
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
    const wefx_add_keyboard_event = instance.exports.wefx_add_keyboard_event;
    const wefx_add_mouse_event = instance.exports.wefx_add_mouse_event;

    // Exported globals defined by the wefx library
    const wefx_keydown = getWASMGlobalValue(memory, instance.exports.wefx_keydown);
    const wefx_keypress = getWASMGlobalValue(memory, instance.exports.wefx_keypress);
    const wefx_keyup = getWASMGlobalValue(memory, instance.exports.wefx_keyup);
    const wefx_mousemove = getWASMGlobalValue(memory, instance.exports.wefx_mousemove);
    const wefx_mousedown = getWASMGlobalValue(memory, instance.exports.wefx_mousedown);
    const wefx_mouseup = getWASMGlobalValue(memory, instance.exports.wefx_mouseup);

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

    const addWEFXKeyboardEvent = (ptr, event_type, e) => {
        const key = e.key ? e.key.charCodeAt(0) : 0;
        // NOTE: This could be extended to take more metadata, e.g. ctrlKey, altKey, etc.
        wefx_add_keyboard_event(ptr, event_type, e.timeStamp, key);
    };
    const addWEFXMouseEvent = (ptr, t, e, canvas) => {
        const pos = relativeXY(e, canvas);
        wefx_add_mouse_event(ptr, t, e.timeStamp, e.button, pos.x, pos.y);
    };

    document.addEventListener("keydown", (e) => {
        addWEFXKeyboardEvent(wefx_ptr, wefx_keydown, e);
    });
    document.addEventListener("keypress", (e) => {
        addWEFXKeyboardEvent(wefx_ptr, wefx_keypress, e);
    });
    document.addEventListener("keyup", (e) => {
        addWEFXKeyboardEvent(wefx_ptr, wefx_keyup, e);
    });

    canvas.addEventListener("mousemove", (e) => {
        addWEFXMouseEvent(wefx_ptr, wefx_mousemove, e, canvas);
    });
    canvas.addEventListener("mousedown", (e) => {
        addWEFXMouseEvent(wefx_ptr, wefx_mousedown, e, canvas);
    });
    canvas.addEventListener("mouseup", (e) => {
        addWEFXMouseEvent(wefx_ptr, wefx_mouseup, e, canvas);
    });

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
