import crypto from 'node:crypto';

type Where<T> = Partial<Record<keyof T, any>>;

const matchesWhere = <T>(item: T, where?: Where<T>): boolean => {
  if (!where) return true;
  return Object.entries(where).every(([key, value]) => {
    if (value === undefined) return true;
    // @ts-ignore
    return item[key] === value;
  });
};

export const createInMemoryRepo = <T extends { id?: string }>(seed: T[] = []) => {
  let items: T[] = [...seed];

  const saveOne = async (entity: T): Promise<T> => {
    const id = entity.id ?? crypto.randomUUID();
    const idx = items.findIndex((i) => i.id === id);
    if (idx >= 0) {
      items[idx] = { ...items[idx], ...entity, id };
      return items[idx];
    }
    const toSave = { ...entity, id } as T;
    items.push(toSave);
    return toSave;
  };

  return {
    get items() {
      return items;
    },
    create: jest.fn((data: Partial<T>) => ({ ...(data as any) })),
    findOne: jest.fn(async (opts?: { where?: Where<T> }) => {
      const where = opts?.where;
      return items.find((item) => matchesWhere(item, where)) ?? null;
    }),
    find: jest.fn(async (opts?: { where?: Where<T>; order?: any; take?: number }) => {
      let result = items.filter((item) => matchesWhere(item, opts?.where));
      if (opts?.order) {
        const [[orderKey, direction]] = Object.entries(opts.order);
        result = result.sort((a: any, b: any) => {
          if (a[orderKey] === b[orderKey]) return 0;
          return direction === 'DESC'
            ? (a[orderKey] ?? 0) < (b[orderKey] ?? 0)
              ? 1
              : -1
            : (a[orderKey] ?? 0) > (b[orderKey] ?? 0)
              ? 1
              : -1;
        });
      }
      if (opts?.take) {
        result = result.slice(0, opts.take);
      }
      return result;
    }),
    save: jest.fn(async (entity: T | T[]) => {
      if (Array.isArray(entity)) {
        return Promise.all(entity.map((e) => saveOne(e)));
      }
      return saveOne(entity);
    }),
    count: jest.fn(async (opts?: { where?: Where<T> }) => {
      return items.filter((item) => matchesWhere(item, opts?.where)).length;
    }),
    reset: () => {
      items = [];
    },
  };
};
