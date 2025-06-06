package samples.reisig;


public abstract class AbstractTopology extends Topology {
    public final int n;

    public AbstractTopology(int n) {
        this.n = n;
    }

    @Override
    public int[] nodes() {
        int[] result = new int[n];
        for (int i = 0; i < n; i++) {
            result[i] = i;
        }
        return result;
    }
}