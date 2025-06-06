package samples.reisig;

import de.renew.unify.Tuple;
import de.renew.util.Value;


public class TupleTopology extends AbstractTopology {
    private int[][] neighbors;

    public TupleTopology(Tuple tuple) {
        super(tuple.getArity());
        neighbors = new int[n][];
        for (int i = 0; i < n; i++) {
            Tuple subtuple = (Tuple) tuple.getComponent(i);
            int m = subtuple.getArity();
            neighbors[i] = new int[m];
            for (int j = 0; j < m; j++) {
                Value val = (Value) subtuple.getComponent(j);
                Integer k = (Integer) val.value;
                neighbors[i][j] = k.intValue();
            }
        }
    }

    @Override
    public int[] neighbors(int i) {
        return neighbors[i];
    }
}