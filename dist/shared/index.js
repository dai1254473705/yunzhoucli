import { add } from '@yunzhou/util';
export function calculateTotal(prices) {
    return prices.reduce((total, price) => add(total, price), 0);
}
