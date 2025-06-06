public class WeatherDataReader {
    private WeatherNetClass weatherNetToReceiveData;

    public WeatherDataReader(WeatherNetClass weatherNetToReceiveData) {
        this.weatherNetToReceiveData = weatherNetToReceiveData;
    }

    public void askForWeatherData() {
        System.out.println("***in askForWeatheData***");
        try {
            Thread.sleep(3000);
        } catch (InterruptedException e) {
            throw new RuntimeException(e);
        }
        Runnable runnable = new Runnable() {
            @Override
            public void run() { 
                System.out.println("Waiting to send data to weatherNetClass");
                try {
                    Thread.sleep(6000);
                } catch (InterruptedException e) {
                    throw new RuntimeException(e);
                }
                System.out.println("WeatherData: Sending data to weatherNetToReceiveData: " + weatherNetToReceiveData);
                weatherNetToReceiveData.receiveData("weatherData sent");
            }
        };
        Thread thread = new Thread(runnable);
        thread.start();
    }
}

