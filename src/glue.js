const canvas = document.getElementById("root");
const context = {
  video: canvas.getContext('2d'),
  audio: new (window.AudioContext || window.webkitAudioContext)(),
  image: undefined,
  store: {},
  index: 0,
  local: window.localStorage,
  game: undefined,
  memory: undefined,
}

//// event handlers ////////////////////////////////////////////////////////////

const t = () => window.performance.now();

// resize display and tell zig to realloc and redraw the display buffer
window.onresize = _ => {
  canvas.width = window.innerWidth;
  canvas.height = window.innerHeight;
  game.resizeCallback(t(), canvas.width, canvas.height);
}

// prevent right click menu to free it for in game use
canvas.oncontextmenu = e => e.preventDefault();

// send pause/resume events when the window loses/regains focus (user configurable action)
canvas.onfocus       = _ => game.focusCallback(t(), true);
canvas.onblur        = _ => game.focusCallback(t(), false);

// handle mouse events
canvas.onmousemove   = m => game.mouseMoveCallback(t(), m.clientX, m.clientY);
canvas.onmouseup     = m => game.mouseCallback(t(), m.clientX, m.clientY, m.button, true);
canvas.onmousedown   = m => game.mouseCallback(t(), m.clientX, m.clientY, m.button, false);
canvas.onwheel       = m => game.mouseWheelCallback(t(), m.deltaX, m.deltaY, m.deltaZ);

// handle keyboard events
canvas.onkeyup       = k => game.keyCallback(t(), m.keyCode, m.altKey, m.ctrlKey, m.metaKey, m.shiftKey, true);
canvas.onkeydown     = k => game.keyCallback(t(), m.keyCode, m.altKey, m.ctrlKey, m.metaKey, m.shiftKey, false);

// custom game messages (allocated on the zig heap, tag + ?c_void)
// having it allows for message feedback
// TODO: canvas.message = m => game.messageCallback(t(), m.data.tag, m.data.ptr);

//// javascript glue ///////////////////////////////////////////////////////////

// javascript functions visible to zig
const lib = {
  canvas: {
    // move image from wasm heap to canvas
    blit: () => {},
    // bind a newly allocated image buffer (called on canvas/window resize)
    bind: (p, w, h) => {
      const buffer = new Uint8ClampedArray(context.memory, w * h * 4);
      context.image = new ImageData(buffer, w, h);
    },
  },
  window: {
    // reload window (hard reset game)
    reload: () => window.location.reload()
  },
  network: {
    // schedule a fetch for resources over a network
    fetch: (urlp, urll) => {},
  },
  memory: {
    // release javascript reference
    release: rid => { delete context.store[rid]; }
  },
  // TODO: "mqueue": { post: (tag, msg) => channel.postMessage({ "tag": tag, "ptr": msg }) },
}

//// initialization ////////////////////////////////////////////////////////////

fetch("/zig-cache/lib/game.wasm")
.then(response => response.arrayBuffer())
.then(buffer => WebAssembly.instantiate(buffer, lib))
.then(ref => {
  game = ref;
});
