public class ExternalCalculator {
    public static int add(int a, int b) {
        System.out.println("ExternalCalculator: Adding " + a + " and " + b);
        return a + b;
    }

    public double multiply(double x, double y) {
        System.out.println("ExternalCalculator: Multiplying " + x + " and " + y);
        return x * y;
    }
}
