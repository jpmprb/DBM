package samples.reisig;


public class UnionTopology extends Topology {
    private Topology first;
    private Topology second;
    private int[] nodes;

    public UnionTopology(Topology first, Topology second) {
        this.first = first;
        this.second = second;

        nodes = union(first.nodes(), second.nodes());
    }

    @Override
    public int[] nodes() {
        return nodes;
    }

    @Override
    public int[] neighbors(int i) {
        return union(first.neighbors(i), second.neighbors(i));
    }
}