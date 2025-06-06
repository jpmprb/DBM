package pt.ipbeja.weather;// This file was automatically generated. Do not modify.
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.Future;
import java.util.Set;
import java.util.Collection;

import de.renew.engine.simulator.SimulationThreadPool;
import de.renew.net.NetInstance;
import de.renew.net.Place;
import de.renew.net.PlaceInstance;
import de.renew.net.SimulatablePlaceInstance;
import de.renew.engine.searchqueue.SearchQueue;
public class WeatherNetClass
  extends de.renew.net.NetInstanceImpl
{

  private static final org.apache.log4j.Logger logger = org.apache.log4j.Logger
                                                        .getLogger(WeatherNetClass.class);
  private final NetInstance _instance = this;

  public void receiveData(final String ppcityName, final Object ppdata)
  {
      final Object vvcityName=ppcityName;
      final Object vvdata=ppdata;
      SimulationThreadPool.getCurrent().executeAndWait(new Runnable() {
        public void run() {
            de.renew.unify.Tuple inTuple;
            de.renew.unify.Tuple outTuple;
            inTuple=new de.renew.unify.Tuple(2);
            try {
              de.renew.unify.Unify.unify(inTuple.getComponent(0),vvcityName,null);
            } catch (de.renew.unify.Impossible e) {
              throw new RuntimeException("Unification failed unexpectedly.", e);
            }
            try {
              de.renew.unify.Unify.unify(inTuple.getComponent(1),vvdata,null);
            } catch (de.renew.unify.Impossible e) {
              throw new RuntimeException("Unification failed unexpectedly.", e);
            }
            outTuple=de.renew.call.SynchronisationRequest.synchronize(
            _instance,"receiveData",inTuple);
//**only to avoid unused warnings. !BAD! style**
            outTuple.hashCode();
        }
      });
  }
  public WeatherNetClass()
  {
    super();
    Future<Object> future = SimulationThreadPool.getCurrent()
                                 .submitAndWait(new Callable<Object>() {
      public Object call() throws RuntimeException {
        try {
          de.renew.net.Net net = de.renew.net.Net.forName("weathernet");
          net.setEarlyTokens(true);
          initNet(net, true);
          createConfirmation(de.renew.application.SimulatorPlugin.getCurrent().getCurrentEnvironment().getSimulator().currentStepIdentifier());
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
        logger.error("Timeout while waiting for simulation thread to finish", e);
    } catch (ExecutionException e) {
        logger.error("Simulation thread threw an exception", e);
    }
  }
}
