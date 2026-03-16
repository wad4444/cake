import { Phase, Scheduler, SystemContext, SystemTable } from "@rbxts/cake";

declare namespace CakeRunService {
    export const phases: {
        readonly pre_render: Phase;
        readonly pre_simulation: Phase;
        readonly pre_animation: Phase;
        readonly post_simulation: Phase;
        readonly heartbeat: Phase;
    };

    export const initialize_runservice: SystemTable<[Scheduler<any[]>, SystemContext]>
}

export = CakeRunService;