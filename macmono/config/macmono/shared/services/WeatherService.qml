import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string placeName: ""
    property real lat: 0
    property real lon: 0
    property string unit: "c"
    property int cacheMin: 30

    readonly property bool hasLocation: placeName !== ""
    property bool loading: false
    property string error: ""
    property var current: null
    property var daily: []
    property double fetchedAt: 0
    property bool refetchPending: false
    property string fetchKey: ""
    function keyNow() { return lat + "|" + lon + "|" + unit; }
    readonly property bool available: hasLocation && current !== null
    readonly property string unitLabel: unit === "f" ? "°F" : "°C"

    readonly property string forecastUrl: "https://api.open-meteo.com/v1/forecast"
    readonly property string geocodeUrl: "https://geocoding-api.open-meteo.com/v1/search"

    function describe(code) {
        if (code === 0) return "Clear";
        if (code === 1) return "Mostly clear";
        if (code === 2) return "Partly cloudy";
        if (code === 3) return "Overcast";
        if (code === 45 || code === 48) return "Fog";
        if (code >= 51 && code <= 57) return "Drizzle";
        if (code >= 61 && code <= 67) return "Rain";
        if (code >= 71 && code <= 77) return "Snow";
        if (code >= 80 && code <= 82) return "Rain showers";
        if (code === 85 || code === 86) return "Snow showers";
        if (code >= 95) return "Thunderstorm";
        return "Unknown";
    }

    function iconFor(code, isDay) {
        if (code === 0) return isDay ? "sun" : "moon";
        if (code === 1 || code === 2) return isDay ? "cloud-sun" : "cloud-moon";
        if (code === 3) return "cloud";
        if (code === 45 || code === 48) return "fog";
        if (code >= 51 && code <= 57) return "drizzle";
        if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return "rain";
        if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow";
        if (code >= 95) return "storm";
        return "cloud";
    }

    function ensureFresh() {
        if (!hasLocation || loading) return;
        if (current !== null && (Date.now() - fetchedAt) < cacheMin * 60000) return;
        refresh();
    }
    function refresh() {
        if (!hasLocation) return;
        if (fetchProc.running) { refetchPending = true; return; }
        loading = true;
        error = "";
        fetchKey = keyNow();
        fetchProc.command = ["curl", "-sS", "--max-time", "10", "--get",
            "--data-urlencode", "latitude=" + lat,
            "--data-urlencode", "longitude=" + lon,
            "--data-urlencode", "current=temperature_2m,apparent_temperature,weather_code,is_day",
            "--data-urlencode", "daily=weather_code,temperature_2m_max,temperature_2m_min",
            "--data-urlencode", "temperature_unit=" + (unit === "f" ? "fahrenheit" : "celsius"),
            "--data-urlencode", "timezone=auto",
            "--data-urlencode", "forecast_days=5",
            forecastUrl];
        fetchProc.running = true;
    }
    onLatChanged: invalidate()
    onLonChanged: invalidate()
    onUnitChanged: invalidate()
    onPlaceNameChanged: invalidate()
    function invalidate() {
        current = null; daily = []; fetchedAt = 0;
        if (hasLocation) refreshLater.restart();
    }
    Timer { id: refreshLater; interval: 400; onTriggered: root.refresh() }

    Process {
        id: fetchProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (root.fetchKey !== root.keyNow()) { root.loading = root.refetchPending; return; }
                root.loading = false;
                try {
                    const d = JSON.parse(text);
                    if (!d.current || !d.daily) { root.error = d.reason || "No weather data."; return; }
                    root.current = { temp: d.current.temperature_2m, feels: d.current.apparent_temperature,
                                     code: d.current.weather_code, isDay: d.current.is_day === 1 };
                    const out = [];
                    for (let i = 0; i < d.daily.time.length; i++)
                        out.push({ date: d.daily.time[i], code: d.daily.weather_code[i],
                                   max: d.daily.temperature_2m_max[i], min: d.daily.temperature_2m_min[i] });
                    root.daily = out;
                    root.fetchedAt = Date.now();
                } catch (e) { root.error = "Could not read weather data."; }
            }
        }
        onExited: (code) => {
            if (code !== 0) { root.loading = false; root.error = "No connection."; }
            if (root.refetchPending) { root.refetchPending = false; refreshLater.restart(); }
        }
    }

    property var results: []
    property bool searching: false
    property string searchError: ""
    function search(query) {
        const q = String(query || "").trim();
        if (q.length < 2) { results = []; return; }
        searching = true; searchError = "";
        geoProc.running = false;
        geoProc.command = ["curl", "-sS", "--max-time", "10", "--get",
            "--data-urlencode", "name=" + q,
            "--data-urlencode", "count=6",
            "--data-urlencode", "language=en",
            "--data-urlencode", "format=json",
            geocodeUrl];
        geoProc.running = true;
    }
    Process {
        id: geoProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.searching = false;
                try {
                    const d = JSON.parse(text);
                    const out = [];
                    for (const r of (d.results || [])) {
                        const parts = [r.name];
                        if (r.admin1 && r.admin1 !== r.name) parts.push(r.admin1);
                        if (r.country) parts.push(r.country);
                        out.push({ label: parts.join(", "), lat: r.latitude, lon: r.longitude });
                    }
                    root.results = out;
                    if (out.length === 0) root.searchError = "No places found.";
                } catch (e) { root.results = []; root.searchError = "Search failed."; }
            }
        }
        onExited: (code) => { if (code !== 0) { root.searching = false; root.searchError = "No connection."; } }
    }
}
