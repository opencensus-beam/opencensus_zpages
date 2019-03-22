const ws = new WebSocket('ws://localhost:5555/metricz/stream');

ws.addEventListener('message', function (event) {
    const data = JSON.parse(event.data);
    const element = document.getElementById(data.name);

    console.log(element);
});
