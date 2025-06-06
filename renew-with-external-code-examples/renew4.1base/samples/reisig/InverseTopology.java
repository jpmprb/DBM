package samples.reisig;


public class InverseTopology extends Topology {
    private Topology base;

    public InverseTopology(Topology base) {
        this.base = base;
    }

    @Override
    public int[] nodes() {
        return base.nodes();
    }

    @Override
    public int[] neighbors(int i) {
        int[] nodes = nodes();

        int cnt = 0;
        for (int j = 0; j < nodes.length; j++) {
            int[] neighbors = base.neighbors(j);
            for (int k = 0; k < neighbors.length; k++) {
                if (neighbors[k] == i) {
                    cnt++;
                    break;
                }
            }
        }

        int[] result = new int[cnt];
        cnt = 0;
        for (int j = 0; j < nodes.length; j++) {
            int[] neighbors = base.neighbors(j);
            for (int k = 0; k < neighbors.length; k++) {
                if (neighbors[k] == i) {
                    result[cnt++] = j;
                    break;
                }
            }
        }

        return result;
    }
}