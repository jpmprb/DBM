package samples.reisig;

public class SampleTopology extends Topology {
    @Override
    public int[] nodes() {
        return new int[] { 0, 1, 2, 3, 4 };
    }

    @Override
    public int[] neighbors(int i) {
        // directed, strongly connected graph.
        switch (i) {
        case 0:
            return new int[] { 1 };
        case 1:
            return new int[] { 2, 3 };
        case 2:
            return new int[] { 4, 0 };
        case 3:
            return new int[] { 2 };
        case 4:
            return new int[] { 1 };
        }
        return new int[0];
    }
}