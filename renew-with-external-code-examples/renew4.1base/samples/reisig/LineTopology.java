package samples.reisig;


public class LineTopology extends AbstractTopology {
    public LineTopology(int n) {
        super(n);
    }

    @Override
    public int[] neighbors(int i) {
        if (i > 0) {
            return new int[] { i - 1 };
        } else {
            return new int[0];
        }
    }
}