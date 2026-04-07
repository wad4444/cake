type Transformation<T extends unknown[], K extends unknown[]> = (...args: T) =>
    K extends [infer A, ...infer Rest]
        ? Rest extends never[] ? A : LuaTuple<K>: never;
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

export interface Hooks {
    readonly system_ran: unique symbol;
    readonly phase_ran: unique symbol;
    readonly system_added: unique symbol;
    readonly system_removed: unique symbol;
    readonly default_phase_changed: unique symbol;
    readonly system_call: unique symbol;
}

interface HookFunction {
    [Cake.hooks.system_ran]: (system: SystemTable<Callback[]>, context: SystemContext) => void;
    [Cake.hooks.phase_ran]: (phase: Phase) => void;
    [Cake.hooks.system_added]: (system: SystemTable<Callback[]>, context: SystemContext) => void;
    [Cake.hooks.system_removed]: (system: SystemTable<Callback[]>, context: SystemContext) => void;
    [Cake.hooks.default_phase_changed]: (phase: Phase) => void;
    [Cake.hooks.system_call]: (
        system: SystemTable<Callback[]>,
        context: SystemContext,
        run: () => void
    ) => (() => void) | undefined;
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
    set_name(name: string): void;
    get_name(): string;
    get_systems(): SystemTable<Callback[]>[];
    hook<K extends keyof HookFunction>(hook: K, callback: HookFunction[K]): Callback;
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
    export const hooks: Hooks;
    export const globals: {
        dev_mode: boolean;
        default_error_ignore_time: number;
    };
}

export default Cake;