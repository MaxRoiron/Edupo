"use client";

import Link from 'next/link';
import styles from './page.module.css';

export default function RegisterPage() {
    return (
        <div className={styles.container}>
            <div className={styles.card}>
                <div className={styles.header}>
                    <h1 className={styles.title}>Créer un compte</h1>
                    <p className={styles.subtitle}>Rejoignez Edupo !</p>
                </div>

                <form className={styles.form}>
                    <div className={styles.inputGroup}>
                        <label htmlFor="name" className={styles.label}>
                            Nom complet
                        </label>
                        <input
                            type="text"
                            id="name"
                            name="name"
                            className={styles.input}
                            placeholder="Jean Dupont"
                            required
                        />
                    </div>

                    <div className={styles.inputGroup}>
                        <label htmlFor="email" className={styles.label}>
                            Adresse email
                        </label>
                        <input
                            type="email"
                            id="email"
                            name="email"
                            className={styles.input}
                            placeholder="exemple@email.com"
                            required
                        />
                    </div>

                    <div className={styles.inputGroup}>
                        <label htmlFor="password" className={styles.label}>
                            Mot de passe
                        </label>
                        <input
                            type="password"
                            id="password"
                            name="password"
                            className={styles.input}
                            placeholder="••••••••"
                            required
                        />
                    </div>

                    <div className={styles.inputGroup}>
                        <label htmlFor="confirmPassword" className={styles.label}>
                            Confirmer le mot de passe
                        </label>
                        <input
                            type="password"
                            id="confirmPassword"
                            name="confirmPassword"
                            className={styles.input}
                            placeholder="••••••••"
                            required
                        />
                    </div>

                    <button type="submit" className={styles.submitButton}>
                        S'inscrire
                    </button>
                </form>

                <div className={styles.footer}>
                    Déjà un compte ?
                    <Link href="/login" className={styles.link}>
                        Se connecter
                    </Link>
                </div>
            </div>
        </div>
    );
}
