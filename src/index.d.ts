type Transformation<T extends unknown[], K extends unknown[]> = (...args: T) => LuaTuple<K>;
type Cleanuppable = Callback | Instance | thread | RBXScriptConnection;

export type SystemFunction<T extends unknown[]> = (...args: T) => any;

export interface Phase {
    name: string;
}

export interface SystemTable<T extends unknown[]> {
    system: (...args: T) => void;
    name?: string;
    phase?: Phase;
}

export interface SystemContext {
    delta_time: number;
    cleanup: (cleanuppable: Cleanuppable) => () => void;
}

export interface Scheduler<T extends unknown[]> {
    init(...args: T): void;
    start(): void;
    deinit(): void;
    add_system(system: SystemTable<[...T, SystemContext?]>): Callback;
    add_systems(systems: SystemTable<[...T, SystemContext?]>[]): void;
    add_foreign_system<K extends unknown[]>(system: SystemTable<K>, transformation: Transformation<[...T, SystemContext], K>): Callback;
    run_system(system: SystemTable<T>): void;
    run_phase(phase: Phase): void;
    set_default_phase(phase: Phase): void;
    get_default_phase(): Phase;
}

declare namespace Cake {
    export function system<T extends unknown[]>(system: SystemFunction<T>, name?: string, phase?: Phase): SystemTable<T>;
    export function scheduler<T extends unknown[]>(): Scheduler<T>;
    export function scheduler_init<T extends unknown[]>(...args: T): Scheduler<T>;
    export function phase(name: string): Phase;
	
    export const phase_std: {
        readonly on_start: Phase;
        readonly on_stop: Phase;
        readonly never: Phase;
    };
    export const globals: {
        dev_mode: boolean;
        default_error_ignore_time: number;
    };
}

export default Cake;