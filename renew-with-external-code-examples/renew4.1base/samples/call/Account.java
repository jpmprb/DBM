// This file was automatically generated. Do not modify.
package samples.call;

import de.renew.engine.simulator.SimulationThreadPool;
import de.renew.net.NetInstance;

import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;


public class Account extends de.renew.net.NetInstanceImpl {

    private static final org.apache.log4j.Logger logger = org.apache.log4j.Logger
                    .getLogger(Account.class);
    private final NetInstance _instance = this;

    public void deposit(final int ppamount) {
        final Object vvamount = new de.renew.util.Value(
                        new java.lang.Integer(ppamount));
        SimulationThreadPool.getCurrent().executeAndWait(new Runnable() {
	    @Override
	    public void run() {
                de.renew.unify.Tuple inTuple;
                de.renew.unify.Tuple outTuple;
                inTuple = new de.renew.unify.Tuple(1);
                try {
                    de.renew.unify.Unify.unify(inTuple.getComponent(0),
                                    vvamount, null);
                } catch (de.renew.unify.Impossible e) {
                    throw new RuntimeException(
                                    "Unification failed unexpectedly.", e);
                }
                outTuple = de.renew.call.SynchronisationRequest
                                .synchronize(_instance, "deposit", inTuple);
                //**only to avoid unused warnings. !BAD! style**
                outTuple.hashCode();
            }
        });
    }

    public void withdraw(final int ppamount) {
        final Object vvamount = new de.renew.util.Value(
                        new java.lang.Integer(ppamount));
        SimulationThreadPool.getCurrent().executeAndWait(new Runnable() {
	    @Override
            public void run() {
                de.renew.unify.Tuple inTuple;
                de.renew.unify.Tuple outTuple;
                inTuple = new de.renew.unify.Tuple(1);
                try {
                    de.renew.unify.Unify.unify(inTuple.getComponent(0),
                                    vvamount, null);
                } catch (de.renew.unify.Impossible e) {
                    throw new RuntimeException(
                                    "Unification failed unexpectedly.", e);
                }
                outTuple = de.renew.call.SynchronisationRequest
                                .synchronize(_instance, "withdraw", inTuple);
                //**only to avoid unused warnings. !BAD! style**
                outTuple.hashCode();
            }
        });
    }

    public int currentAmount() {
        Future<java.lang.Integer> future = SimulationThreadPool.getCurrent()
                        .submitAndWait(new Callable<java.lang.Integer>() {
                            public java.lang.Integer call()
                                            throws RuntimeException {
                                Object vvreturn;
                                de.renew.unify.Tuple inTuple;
                                de.renew.unify.Tuple outTuple;
                                inTuple = new de.renew.unify.Tuple(1);
                                try {
                                    de.renew.expression.CallExpression
                                                    .expressionConstraint(
                                                                    new de.renew.unify.Variable(),
                                                                    new de.renew.formalism.function.CastFunction(
                                                                                    java.lang.Integer.TYPE),
                                                                    new de.renew.unify.Variable(
                                                                                    inTuple.getComponent(
                                                                                                    0),
                                                                                    null),
                                                                    null);
                                } catch (de.renew.unify.Impossible e) {
                                    throw new RuntimeException(
                                                    "Unification failed unexpectedly.",
                                                    e);
                                }
                                outTuple = de.renew.call.SynchronisationRequest
                                                .synchronize(_instance,
                                                                "amount",
                                                                inTuple);
                                //**only to avoid unused warnings. !BAD! style**
                                outTuple.hashCode();
                                vvreturn = outTuple.getComponent(0);
                                return ((de.renew.util.Value) vvreturn)
                                                .intValue();
                            }
                        });
        try {
            return future.get();
        } catch (InterruptedException e) {
            logger.error("Timeout while waiting for simulation thread to finish",
                            e);
        } catch (ExecutionException e) {
            logger.error("Simulation thread threw an exception", e);
        }

        // We should never return nothing but some error occured befor.
        return 0;
    }

    public Account() {
        super();
        Future<Object> future = SimulationThreadPool.getCurrent()
                        .submitAndWait(new Callable<Object>() {
                            public Object call() throws RuntimeException {
                                try {
                                    de.renew.net.Net net = de.renew.net.Net
                                                    .forName("account");
                                    net.setEarlyTokens(true);
                                    initNet(net, true);
                                    createConfirmation(
                                                    de.renew.application.SimulatorPlugin
                                                                    .getCurrent()
                                                                    .getCurrentEnvironment()
                                                                    .getSimulator()
                                                                    .currentStepIdentifier());
                                } catch (de.renew.net.NetNotFoundException e) {
                                    throw new RuntimeException(e.toString(), e);
                                } catch (de.renew.unify.Impossible e) {
                                    throw new RuntimeException(e.toString(), e);
                                }
                                return null;
                            }
                        });
        try {
            future.get();
        } catch (InterruptedException e) {
            logger.error("Timeout while waiting for simulation thread to finish",
                            e);
        } catch (ExecutionException e) {
            logger.error("Simulation thread threw an exception", e);
        }
    }
}
