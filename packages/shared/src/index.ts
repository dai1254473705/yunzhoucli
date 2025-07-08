import { add } from '@yunzhou/util';

export function calculateTotal(prices: number[]): number {
 return prices.reduce((total, price) => add(total, price), 0);
}