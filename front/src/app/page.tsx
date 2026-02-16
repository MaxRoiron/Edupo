"use client";

import LawCard from '@/components/LawCard';
import { laws } from '@/libs/laws';
import styles from './page.module.css';

export default function Home() {
  return (
    <main className={styles.container}>
      <header className={styles.hero}>
        <h1 className={styles.title}>Nouvelles Lois Votées</h1>
        <p className={styles.subtitle}>
          Retrouvez les dernières législations adoptées par le Parlement français.
        </p>
      </header>

      <section className={styles.lawsList}>
        {laws.map((law) => (
          <LawCard key={law.id} law={law} />
        ))}
      </section>
    </main>
  );
}