package pt.ipbeja.weather;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.io.IOException;
import org.json.JSONObject;
import org.json.JSONException;
import java.util.HashMap;
import java.util.Map;
import java.util.Iterator;
import java.util.Formatter; // Still used for convertMapToString
import java.util.Collections;

public class WeatherDataReader {

    // JSON Key constants
    private static final String KEY_CURRENT_WEATHER = "current_weather";

    private WeatherNetClass weatherNetToReceiveData;
    private double latitude;
    private double longitude;
    private HttpClient httpClient;

    public WeatherDataReader(WeatherNetClass weatherNetToReceiveData, double latitude, double longitude) {
        this.weatherNetToReceiveData = weatherNetToReceiveData;
        this.latitude = latitude;
        this.longitude = longitude;
        this.httpClient = HttpClient.newHttpClient();
    }

    public void askForWeatherData() {
        System.out.println("*** in askForWeatherData ***");

        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                System.out.println("Preparing to fetch weather data...");
                try {
                    String apiUrl = String.format(
                            "https://api.open-meteo.com/v1/forecast?latitude=%.2f&longitude=%.2f&current_weather=true",
                            latitude, longitude);

                    HttpRequest request = HttpRequest.newBuilder()
                            .uri(URI.create(apiUrl))
                            .GET()
                            .build();

                    System.out.println("Sending request to: " + apiUrl);
                    HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

                    if (response.statusCode() == 200) {
                        String responseBody = response.body();
                        System.out.println("Raw response: " + responseBody);

                        Map<String, Double> weatherDataMap = parseWeatherData(responseBody);

                        // Print the key-value pairs immediately after parsing
                        System.out.println("--- Parsed Weather Data (within askForWeatherData) ---");
                        if (weatherDataMap.isEmpty()) {
                            System.out.println("  Map is empty after parsing.");
                        } else {
                            for (Map.Entry<String, Double> entry : weatherDataMap.entrySet()) {
                                System.out.printf("  %s: %.2f\n", entry.getKey(), entry.getValue());
                            }
                        }
                        System.out.println("----------------------------------------------------");

                        System.out.println("WeatherData (as Map): Sending data to weatherNetToReceiveData...");
                        weatherNetToReceiveData.receiveData(weatherDataMap);

                    } else {
                        String errorMessage = "Error: Could not fetch weather data. Status code: " + response.statusCode();
                        System.err.println(errorMessage);
                        weatherNetToReceiveData.receiveData(Collections.emptyMap());
                    }

                } catch (IOException | InterruptedException e) {
                    String errorMessage = "Error: Exception during data fetch - " + e.getMessage();
                    System.err.println(errorMessage);
                    e.printStackTrace();
                    weatherNetToReceiveData.receiveData(Collections.emptyMap());
                    if (e instanceof InterruptedException) {
                        Thread.currentThread().interrupt();
                    }
                } catch (JSONException e) {
                    String errorMessage = "Error: Exception during data parsing - " + e.getMessage();
                    System.err.println(errorMessage);
                    e.printStackTrace();
                    weatherNetToReceiveData.receiveData(Collections.emptyMap());
                }
            }
        };
        Thread thread = new Thread(runnable);
        thread.start();
    }

    private Map<String, Double> parseWeatherData(String jsonData) throws JSONException {
        Map<String, Double> weatherDataMap = new HashMap<>();
        JSONObject root = new JSONObject(jsonData);

        Iterator<String> rootKeys = root.keys();
        while (rootKeys.hasNext()) {
            String key = rootKeys.next();
            Object value = root.get(key);
            if (value instanceof Number) {
                weatherDataMap.put(key, root.getDouble(key));
            }
        }

        if (root.has(KEY_CURRENT_WEATHER)) {
            JSONObject currentWeatherObject = root.getJSONObject(KEY_CURRENT_WEATHER);
            Iterator<String> currentWeatherKeys = currentWeatherObject.keys();
            while (currentWeatherKeys.hasNext()) {
                String key = currentWeatherKeys.next();
                Object value = currentWeatherObject.get(key);
                if (value instanceof Number) {
                    weatherDataMap.put(KEY_CURRENT_WEATHER + "_" + key, currentWeatherObject.getDouble(key));
                }
            }
        }
        return weatherDataMap;
    }

    private String convertMapToString(Map<String, Double> map) {
        if (map == null || map.isEmpty()) {
            return "No numerical weather data parsed or available.";
        }
        StringBuilder sb = new StringBuilder("Parsed Weather Data (Map):\n");
        try (Formatter formatter = new Formatter(sb)) {
            for (Map.Entry<String, Double> entry : map.entrySet()) {
                formatter.format("  %s: %.2f\n", entry.getKey(), entry.getValue());
            }
        }
        return sb.toString().trim();
    }

    /// Test the WeatherDataReader class
    public static void main(String[] args) {
        WeatherNetClass networkRelay = new WeatherNetClass();
        WeatherDataReader reader = new WeatherDataReader(networkRelay, 52.52, 13.41); // Berlin
        reader.askForWeatherData();

        System.out.println("\nSimulating a request to a potentially problematic endpoint (for testing error handling if it occurs):");
        WeatherDataReader errorReader = new WeatherDataReader(networkRelay, 999.99, 999.99); // Invalid coordinates likely
        errorReader.askForWeatherData();


        System.out.println("\nMain thread continues to run while weather data is fetched asynchronously...");
        try {
            Thread.sleep(7000);
        } catch (InterruptedException e) {
            e.printStackTrace();
            Thread.currentThread().interrupt();
        }

        System.out.println("\n--- Demonstrating Map parser with sample JSON (direct use) ---");
        String sampleJsonData = "{\"latitude\":52.52,\"longitude\":13.41,\"generationtime_ms\":0.2,\"utc_offset_seconds\":0,\"timezone\":\"GMT\",\"timezone_abbreviation\":\"GMT\",\"elevation\":38.0,\"current_weather_units\":{\"time\":\"iso8601\",\"interval\":\"seconds\",\"temperature\":\"°F\",\"windspeed\":\"km/h\",\"winddirection\":\"°\",\"is_day\":\"\",\"weathercode\":\"wmo code\"},\"current_weather\":{\"time\":\"2023-10-27T12:00\",\"interval\":900,\"temperature\":59.0,\"windspeed\":10.0,\"winddirection\":270,\"is_day\":1,\"weathercode\":3}}";

        try {
            System.out.println("Parsing sample JSON with Map-returning method:");
            Map<String, Double> dataMap = reader.parseWeatherData(sampleJsonData);

            System.out.println("Demonstrating convertMapToString utility:");
            System.out.println(reader.convertMapToString(dataMap));

            System.out.println("\nDemonstrating WeatherNetClass receiving map directly (simulated):");
            networkRelay.receiveData(dataMap);

        } catch (JSONException e) {
            System.err.println("Error during manual parsing demonstration: " + e.getMessage());
            e.printStackTrace();
        }

        System.out.println("\nMain thread finished.");
    }
}

///**
// * Dummy implementation of WeatherNetClass for testing purposes.
// * Only includes receiveData(Map<String, Double> dataMap).
// * The printing logic for map contents is now more direct.
// */
//class WeatherNetClass {
//    public void receiveData(Map<String, Double> dataMap) {
//        System.out.println("WeatherNetClass received data map:"); // Header for context
//        if (dataMap == null || dataMap.isEmpty()) {
//            System.out.println("  Map is null or empty (possibly indicating an error or no data).");
//            return;
//        }
//        // Iterate through the map and print each key-value pair directly to standard output
//        for (Map.Entry<String, Double> entry : dataMap.entrySet()) {
//            // Using printf for formatted output of each line
//            System.out.printf("  %s: %.2f\n", entry.getKey(), entry.getValue());
//        }
//    }
//}
