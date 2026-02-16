"use client";

import { getLaw } from '@/libs/laws';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { use } from 'react';
import styles from './page.module.css';

interface PageProps {
  params: Promise<{
    id: string;
  }>;
}

export default function LawDetail({ params }: PageProps) {
  const { id } = use(params);
  const law = getLaw(id);

  if (!law) {
    notFound();
  }

  return (
    <main className={styles.container}>
      <Link href="/" className={styles.backLink}>
        ← Retour aux lois
      </Link>

      <article className={styles.lawArticle}>
        <header className={styles.lawHeader}>
          <div className={styles.lawMeta}>
            <span className={styles.lawCategory}>{law.category}</span>
            <span className="separator">•</span>
            <span className="law-date">Promulguée le {law.date}</span>
          </div>
          <h1 className={styles.lawTitle}>{law.title}</h1>
        </header>

        <section className="law-content">
          <div className={styles.summaryBox}>
            <h3>En bref</h3>
            <p>{law.summary}</p>
          </div>

          <div className="details-box">
            <h3>Ce que dit la loi</h3>
            <p className={styles.detailsText}>{law.details}</p>
          </div>
        </section>
      </article>
    </main>
  );
}
