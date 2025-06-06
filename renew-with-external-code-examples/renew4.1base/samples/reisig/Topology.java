package samples.reisig;

import de.renew.unify.Tuple;
import de.renew.util.Value;


public abstract class Topology {

    /**
     * Returns the set of all nodes in this topology.
     *
     * @return an array of all node ids.
     **/
    public abstract int[] nodes();

    /**
     * Returns the set of all nodes neigbored to the node with id x in this
     * topology.
     *
     * @return an array of all adjacent node ids.
     **/
    public abstract int[] neighbors(int x);


    /**
     * Convenience Method:
     * <code>r(x) := {x} x neighbors(x)</code>.
     *
     * @param x id of the node whose neighbors are requested
     * @return an array of pairs <code>[x, yi]</code> where each pair
     * represents one connection from x to a neighbor.
     **/
    public Tuple[] r(final int x) {
        return prod(x, neighbors(x));
    }

    /**
     * Convenience Method:
     * <code>N(x) := neighbors(x) x {x}</code>.
     *
     * @param x id of the node whose neighbors are requested
     * @return an array of pairs <code>[yi, x]</code> where each pair
     * represents one message going from <code>x</code> to the neighbor
     * <code>yi</code> of <code>x</code>.
     **/
    public Tuple[] N(final int x) {
        return prod(neighbors(x), x);
    }

    /**
     * Convenience Method:
     * <code>NI(x) := {x} x neighbors(x) = r(x)</code>.
     *
     * @param x id of the node whose neighbors are requested
     * @return an array of pairs <code>[yi, x]</code> where each pair
     * represents one message going from the neighbor
     * <code>yi</code> of <code>x</code> to <code>x</code>.
     **/
    public Tuple[] NI(final int x) {
        return r(x);
    }

    /**
     * Convenience Method:
     * <code>Q(x) := neighbors(x) x {x} x {"?"}</code>.
     *
     * @param x id of the node whose neighbors should receive query messages
     * @return an array of pairs <code>[yi, x]</code> where each pair
     * represents one query message going from <code>x</code> to the neighbor
     * <code>yi</code> of <code>x</code>.
     **/
    public Tuple[] Q(final int x) {
        return appendCart(N(x), "?");
    }

    /**
     * Convenience Method:
     * <code>R(x) := {x} x neighbors(x) x {"!"}</code>.
     *
     * @param x id of the node whose neighbors should have sent answer messages
     * @return an array of pairs <code>[yi, x]</code> where each pair
     * represents one answer message going from the neighbor
     * <code>yi</code> of <code>x</code> to <code>x</code>.
     **/
    public Tuple[] R(final int x) {
        return appendCart(NI(x), "!");
    }

    /**
     * Computes the complement of the given subset of nodes with respect to
     * all nodes in this topology.
     * <p>
     * <code> complement(M) := nodes() \ M </code>
     * </p>
     * <code>M</code> must be a subset of <code>nodes()</code>.
     *
     * @param subset an array of node ids
     * @return a complementary array of node ids
     **/
    public int[] complement(final int[] subset) {
        final int[] nodes = nodes();
        final int complementSize = nodes.length - subset.length;
        if ((complementSize < 0) || (complementSize > nodes.length)) {
            throw new IllegalArgumentException(
                            "Subset size violates constraint: 0 <= "
                                            + subset.length + " <= "
                                            + nodes.length);
        }
        final int[] result = new int[complementSize];
        int fillpos = 0;
        for (int i = 0; i < nodes.length; i++) {
            int nodeInQuestion = nodes[i];
            boolean isInSubset = false;
            for (int j = 0; (j < subset.length) && !isInSubset; j++) {
                if (nodeInQuestion == subset[i]) {
                    isInSubset = true;
                }
            }
            if (!isInSubset) {
                result[fillpos] = nodeInQuestion;
                fillpos++;
            }
        }
        return result;
    }

    /**
     * Returns all existing connections within the topology.
     *
     * @return an array of pairs, each representing one connection within
     * the topology.
     **/
    public Tuple[] all() {
        int cnt = 0;
        int[] nodes = nodes();
        for (int i = 0; i < nodes.length; i++) {
            cnt = cnt + neighbors(i).length;
        }
        Tuple[] result = new Tuple[cnt];
        cnt = 0;
        for (int i = 0; i < nodes.length; i++) {
            int[] n = neighbors(i);
            for (int j = 0; j < n.length; j++) {
                result[cnt++] = makePair(i, n[j]);
            }
        }
        return result;
    }

    // --------------------------------------- static helper methods ------

    public static Tuple makePair(int x, int y) {
        Object[] arr = new Object[2];
        arr[0] = new Value(Integer.valueOf(x));
        arr[1] = new Value(Integer.valueOf(y));
        return new Tuple(arr, null);
    }

    public static void sort(int[] x) {
        for (int i = x.length - 1; i > 0; i--) {
            for (int j = 0; j < i; j++) {
                if (x[i] < x[j]) {
                    int h = x[i];
                    x[i] = x[j];
                    x[j] = h;
                }
            }
        }
    }

    public static int[] union(int[] x, int[] y) {
        x = x.clone();
        y = y.clone();

        sort(x);
        sort(y);
        int[] temp = new int[x.length + y.length];
        int i = 0;
        int j = 0;
        int k = 0;
        while (i < x.length || j < y.length) {
            int t;
            if (i == x.length || (j != y.length && x[i] > y[j])) {
                t = y[j++];
            } else {
                t = x[i++];
            }
            if (k == 0 || t > temp[k - 1]) {
                temp[k++] = t;
            }
        }
        int[] result = new int[k];
        for (i = 0; i < k; i++) {
            result[i] = temp[i];
        }
        return result;
    }

    // Cartesian product
    public static Tuple[] cart(int[] x, int[] y) {
        Tuple[] result = new Tuple[x.length * y.length];
        for (int i = 0; i < x.length; i++) {
            for (int j = 0; j < x.length; j++) {
                result[i] = makePair(x[i], y[j]);
            }
        }
        return result;
    }

    /**
     * Appends another component to all tuples in a cartesian product.
     * <code>appendCart(M, x) := {(a,b,x)|(a,b) in M}</code>.
     *
     * @param tuples a set of tuples.
     * @param x some component to append.
     * @return a set of augmented tuples.
     **/
    public static Tuple[] appendCart(final Tuple[] tuples, final Object x) {
        Tuple[] result = new Tuple[tuples.length];
        for (int i = 0; i < tuples.length; i++) {
            int componentCount = tuples[i].getArity();
            Object[] arr = new Object[componentCount + 1];
            for (int j = 0; j < componentCount; j++) {
                arr[j] = tuples[i].getComponent(j);
            }
            arr[componentCount] = x;
            result[i] = new Tuple(arr, null);
        }
        return result;
    }

    /**
     * Appends another component to all tuples in a cartesian product.
     * <code>appendCart(M, x) := {(a1,...,ak,x)|(a1,...,ak) in M}</code>.
     *
     * @param tuples a set of tuples.
     * @param x some <code>int</code> component to append.
     * @return a set of augmented tuples.
     **/
    public static Tuple[] appendCart(final Tuple[] tuples, final int x) {
        Tuple[] result = new Tuple[tuples.length];
        for (int i = 0; i < tuples.length; i++) {
            int componentCount = tuples[i].getArity();
            Object[] arr = new Object[componentCount + 1];
            for (int j = 0; j < componentCount; j++) {
                arr[j] = tuples[i].getComponent(j);
            }
            arr[componentCount] = new Value(Integer.valueOf(x));
            result[i] = new Tuple(arr, null);
        }
        return result;
    }

    // Vector product
    public static Tuple[] prod(int[] x, int y) {
        Tuple[] result = new Tuple[x.length];
        for (int i = 0; i < x.length; i++) {
            result[i] = makePair(x[i], y);
        }
        return result;
    }

    public static Tuple[] prod(int x, int[] y) {
        Tuple[] result = new Tuple[y.length];
        for (int i = 0; i < y.length; i++) {
            result[i] = makePair(x, y[i]);
        }
        return result;
    }

    public static Tuple[] prod(int[] x, int[] y) {
        Tuple[] result = new Tuple[x.length];
        for (int i = 0; i < x.length; i++) {
            result[i] = makePair(x[i], y[i]);
        }
        return result;
    }

    public static Tuple[] pairs(int[] x) {
        return prod(x, x);
    }

    /**
     * Computes a subset where the given element has been removed.
     * It is assumed that the given array does not contain any duplicates.
     *
     * @param set a set of <code>Tuple</code>s
     * @param toExclude a <code>Tuple</code> to exclude
     * @return the set without the given element (or the original set, if the
     * element to exclude was not found within the set).
     **/
    public static Tuple[] exclude(final Tuple[] set, final Tuple toExclude) {
        // We cannot exclude anything from empty sets.
        if (set.length == 0) {
            return set;
        }
        final Tuple[] result = new Tuple[set.length - 1];
        int skipIfFound = 0;
        for (int i = 0; i < result.length; i++) {
            if (toExclude.equals(set[i + skipIfFound])) {
                assert skipIfFound == 0 : "Encountered duplicate";
                skipIfFound = 1;
            }
            result[i] = set[i + skipIfFound];
        }
        if (skipIfFound == 0) {
            // up to now, we did not find the element to exclude.
            // But the last element of the original set has not been
            // checked yet.
            if (!toExclude.equals(set[result.length])) {
                // Return the original set since the element has not been found.
                return set;
            }
        }
        // Return the reduced copy of the set.
        return result;
    }

    /**
     * Computes a subset where the given element has been removed.
     * It is assumed that the given array does not contain any duplicates.
     *
     * @param set a set of <code>int</code>s
     * @param toExclude a <code>int</code> to exclude
     * @return the set without the given element (or the original set, if the
     * element to exclude was not found within the set).
     **/
    public static int[] exclude(final int[] set, final int toExclude) {
        // We cannot exclude anything from empty sets.
        if (set.length == 0) {
            return set;
        }
        final int[] result = new int[set.length - 1];
        int skipIfFound = 0;
        for (int i = 0; i < result.length; i++) {
            if (toExclude == set[i + skipIfFound]) {
                assert skipIfFound == 0 : "Encountered duplicate";
                skipIfFound = 1;
            }
            result[i] = set[i + skipIfFound];
        }
        if (skipIfFound == 0) {
            // up to now, we did not find the element to exclude.
            // But the last element of the original set has not been
            // checked yet.
            if (!(toExclude == set[result.length])) {
                // Return the original set since the element has not been found.
                return set;
            }
        }
        // Return the reduced copy of the set.
        return result;
    }
}