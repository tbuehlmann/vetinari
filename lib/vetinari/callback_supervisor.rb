module Vetinari
  class CallbackSupervisor < Celluloid::SupervisionGroup
    supervise MyActor, :as => :my_actor
    supervise AnotherActor, :as => :another_actor, :args => [{:start_working_right_now => true}]
    pool MyWorker, :as => :my_worker_pool, :size => 5
  end
end
