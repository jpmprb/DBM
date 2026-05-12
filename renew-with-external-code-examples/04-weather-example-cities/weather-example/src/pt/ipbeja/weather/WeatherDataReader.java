package pt.ipbeja.weather;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import org.json.JSONException;
import org.json.JSONObject;
import java.util.Locale;

public class WeatherDataReader {

    // JSON Key constants
    private static final String KEY_CURRENT_WEATHER = "current_weather";

    // Partilha do HttpClient (estático e único)
    private static final HttpClient HTTP_CLIENT = 
            HttpClient.newHttpClient();

    private final WeatherNetClass weatherNetToReceiveData;

    public WeatherDataReader(WeatherNetClass weatherNetToReceiveData) {
        this.weatherNetToReceiveData = weatherNetToReceiveData;
    }

    public void askForWeatherData(String cityName, double latitude, 
            double longitude) {
        System.out.println("*** in askForWeatherData for " + 
                cityName + " ***");
        System.out.println("Preparing to fetch weather data " +
                "for " + cityName + "...");

        String apiUrl = String.format(Locale.US,
                "https://api.open-meteo.com/v1/forecast?" +
                "latitude=%.2f&longitude=%.2f&" +
                "current_weather=true",
                latitude, longitude);

        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(apiUrl))
                .GET()
                .build();

        System.out.println("Sending request to: " + apiUrl);

        // API do Java para pedidos assíncronos
        // Elimina a necessidade de criar Threads manualmente
        HTTP_CLIENT.sendAsync(request, 
                HttpResponse.BodyHandlers.ofString())
                .thenAccept(response -> processResponse(cityName, 
                        response))
                .exceptionally(throwable -> {
                    String errorMessage = 
                            "Error: Exception during data fetch for " + 
                            cityName + " - " + throwable.getMessage();
                    System.err.println(errorMessage);
                    weatherNetToReceiveData.receiveData(cityName, 
                            Collections.emptyMap());
                    return null;
                });
    }

    private void processResponse(String cityName, 
            HttpResponse<String> response) {
        if (response.statusCode() == 200) {
            String responseBody = response.body();
            System.out.println("Raw response for " + 
                    cityName + ": " + responseBody);

            try {
                Map<String, Double> weatherDataMap = 
                        parseWeatherData(responseBody);

                System.out.println("--- Parsed Weather Data " +
                        "for " + cityName + 
                        " (within askForWeatherData) ---");
                
                if (weatherDataMap.isEmpty()) {
                    System.out.println("  Map is empty after parsing.");
                } else {
                    for (Map.Entry<String, Double> entry : 
                            weatherDataMap.entrySet()) {
                        System.out.printf("  %s: %.2f\n", 
                                entry.getKey(), entry.getValue());
                    }
                }
                
                System.out.println("---------------------------------" +
                        "-----------------------------------");
                System.out.println("Going to send parsed data to " +
                        "the net for city " + cityName);
                weatherNetToReceiveData.receiveData(cityName, 
                        weatherDataMap);
                System.out.println("---------------------------------" +
                        "-----------------------------------");

            } catch (JSONException e) {
                String errorMessage = 
                        "Error: Exception during data parsing " + 
                        "for " + cityName + " - " + e.getMessage();
                System.err.println(errorMessage);
                e.printStackTrace();
                weatherNetToReceiveData.receiveData(cityName, 
                        Collections.emptyMap());
            }
        } else {
            String errorMessage = 
                    "Error: Could not fetch weather data " +
                    "for " + cityName + ". Status code: " + 
                    response.statusCode();
            System.err.println(errorMessage);
            weatherNetToReceiveData.receiveData(cityName, 
                    Collections.emptyMap());
        }
    }

    private Map<String, Double> parseWeatherData(String jsonData) 
            throws JSONException {
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
            JSONObject currentWeatherObject = 
                    root.getJSONObject(KEY_CURRENT_WEATHER);
            Iterator<String> currentWeatherKeys = 
                    currentWeatherObject.keys();
            while (currentWeatherKeys.hasNext()) {
                String key = currentWeatherKeys.next();
                Object value = currentWeatherObject.get(key);
                if (value instanceof Number) {
                    weatherDataMap.put(KEY_CURRENT_WEATHER + "_" + key, 
                            currentWeatherObject.getDouble(key));
                }
            }
        }
        return weatherDataMap;
    }
}
