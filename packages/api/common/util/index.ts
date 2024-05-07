export function getDefinedValues<T>(input: T) {
  return Object.entries(input).reduce(
    (acc, [key, value]) => {
      if (value !== undefined) {
        acc[key] = value;
      }

      return acc;
    },
    {} as Partial<T>,
  );
}
