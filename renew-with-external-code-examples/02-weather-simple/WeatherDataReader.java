import java.util.concurrent.CompletableFuture;

public class WeatherDataReader {
    private final WeatherNetClass weatherNetToReceiveData;

    public WeatherDataReader(WeatherNetClass weatherNetToReceiveData) {
        this.weatherNetToReceiveData = weatherNetToReceiveData;
    }

    public void askForWeatherData() {
        System.out.println("***in askForWeatheData***");
        sleep(3000);

        CompletableFuture.runAsync(() -> { 
            System.out.println("Waiting to send data to weatherNetClass");
            sleep(6000);
            
            System.out.println("WeatherData: Sending data to weatherNetToReceiveData: " + weatherNetToReceiveData);
            weatherNetToReceiveData.receiveData("weatherData sent");
        });
    }

    // Método auxiliar para manter o código principal mais curto
    private void sleep(long millis) {
        try {
            Thread.sleep(millis);
        } catch (InterruptedException e) {
            // Restaura o status de interrupção da thread (boa prática em Java)
            Thread.currentThread().interrupt();
            throw new RuntimeException("Thread foi interrompida durante o sleep", e);
        }
    }
}