// This file was automatically generated. Do not modify.
package samples.call;

import de.renew.engine.simulator.SimulationThreadPool;
import de.renew.net.NetInstance;

import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;


public class EnumBag extends de.renew.net.NetInstanceImpl
                implements java.util.Enumeration {

    private static final org.apache.log4j.Logger logger = org.apache.log4j.Logger
                    .getLogger(EnumBag.class);
    private final NetInstance _instance = this;

    @Override
    public boolean hasMoreElements() {
        Future<java.lang.Boolean> future = SimulationThreadPool.getCurrent()
                        .submitAndWait(new Callable<java.lang.Boolean>() {
			    @Override
			    public java.lang.Boolean call()
                                            throws RuntimeException {
                                Object vvreturn;
                                de.renew.unify.Tuple inTuple;
                                de.renew.unify.Tuple outTuple;
                                Object vvinstance;
                                inTuple = new de.renew.unify.Tuple(1);
                                outTuple = de.renew.call.SynchronisationRequest
                                                .synchronize(_instance,
                                                                "hasMoreElements",
                                                                inTuple);
                                //**only to avoid unused warnings. !BAD! style**
                                outTuple.hashCode();
                                vvinstance = outTuple.getComponent(0);
                                inTuple = new de.renew.unify.Tuple(2);
                                try {
                                    de.renew.unify.Unify.unify(
                                                    inTuple.getComponent(0),
                                                    vvinstance, null);
                                } catch (de.renew.unify.Impossible e) {
                                    throw new RuntimeException(
                                                    "Unification failed unexpectedly.",
                                                    e);
                                }
                                try {
                                    de.renew.expression.CallExpression
                                                    .expressionConstraint(
                                                                    new de.renew.unify.Variable(),
                                                                    new de.renew.formalism.function.CastFunction(
                                                                                    java.lang.Boolean.TYPE),
                                                                    new de.renew.unify.Variable(
                                                                                    inTuple.getComponent(
                                                                                                    1),
                                                                                    null),
                                                                    null);
                                } catch (de.renew.unify.Impossible e) {
                                    throw new RuntimeException(
                                                    "Unification failed unexpectedly.",
                                                    e);
                                }
                                outTuple = de.renew.call.SynchronisationRequest
                                                .synchronize(_instance,
                                                                "result",
                                                                inTuple);
                                //**only to avoid unused warnings. !BAD! style**
                                outTuple.hashCode();
                                vvreturn = outTuple.getComponent(1);
                                return ((de.renew.util.Value) vvreturn)
                                                .booleanValue();
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
        return false;
    }

    public java.lang.Object nextElement() {
        Future<java.lang.Object> future = SimulationThreadPool.getCurrent()
                        .submitAndWait(new Callable<java.lang.Object>() {
                            public java.lang.Object call()
                                            throws RuntimeException {
                                Object vvreturn;
                                de.renew.unify.Tuple inTuple;
                                de.renew.unify.Tuple outTuple;
                                Object vvinstance;
                                inTuple = new de.renew.unify.Tuple(1);
                                outTuple = de.renew.call.SynchronisationRequest
                                                .synchronize(_instance,
                                                                "nextElement",
                                                                inTuple);
                                //**only to avoid unused warnings. !BAD! style**
                                outTuple.hashCode();
                                vvinstance = outTuple.getComponent(0);
                                inTuple = new de.renew.unify.Tuple(2);
                                try {
                                    de.renew.unify.Unify.unify(
                                                    inTuple.getComponent(0),
                                                    vvinstance, null);
                                } catch (de.renew.unify.Impossible e) {
                                    throw new RuntimeException(
                                                    "Unification failed unexpectedly.",
                                                    e);
                                }
                                try {
                                    de.renew.expression.CallExpression
                                                    .expressionConstraint(
                                                                    new de.renew.unify.Variable(),
                                                                    new de.renew.formalism.function.CastFunction(
                                                                                    java.lang.Object.class),
                                                                    new de.renew.unify.Variable(
                                                                                    inTuple.getComponent(
                                                                                                    1),
                                                                                    null),
                                                                    null);
                                } catch (de.renew.unify.Impossible e) {
                                    throw new RuntimeException(
                                                    "Unification failed unexpectedly.",
                                                    e);
                                }
                                outTuple = de.renew.call.SynchronisationRequest
                                                .synchronize(_instance,
                                                                "result",
                                                                inTuple);
                                //**only to avoid unused warnings. !BAD! style**
                                outTuple.hashCode();
                                vvreturn = outTuple.getComponent(1);
                                return (java.lang.Object) vvreturn;
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
        return null;
    }

    public EnumBag() {
        super();
        Future<Object> future = SimulationThreadPool.getCurrent()
                        .submitAndWait(new Callable<Object>() {
                            public Object call() throws RuntimeException {
                                try {
                                    de.renew.net.Net net = de.renew.net.Net
                                                    .forName("enumbag");
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
