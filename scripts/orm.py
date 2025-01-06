from sqlalchemy import Column, Integer, String, ForeignKey, create_engine, select, func
from sqlalchemy.orm import DeclarativeBase, Session, relationship, aliased
import os

class Base(DeclarativeBase):
    pass

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True)
    username = Column(String(20), unique=True, nullable=False)
    password = Column(String(64), nullable=False)

    def __repr__(self) -> str:
        return f"User(id={self.id!r}, name={self.username!r}"

class Follow(Base):
    __tablename__ = "follows"

    from_user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)
    to_user_id = Column(Integer, ForeignKey("users.id"), primary_key=True)

    from_user = relationship("User", foreign_keys=[from_user_id], backref="follows")
    to_user = relationship("User", foreign_keys=[to_user_id], backref="followed_by")

password = os.getenv("POSTGRES_PASSWORD")
DATABASE_URL = f"postgresql://postgres:{password}@postgres:5432/postgres"
engine = create_engine(DATABASE_URL)

with Session(engine) as session:
    person = "AnnaJoy92"

    u1 = aliased(User)
    u2 = aliased(User)
    f1 = aliased(Follow)
    f2 = aliased(Follow)

    query = (
        select(
            u2.username.label("username"),
            func.count().label("fic")
        )
        .select_from(u1)
        .join(f1, u1.id == f1.from_user_id)
        .join(f2, f1.to_user_id == f2.from_user_id)
        .join(u2, f2.to_user_id == u2.id)
        .where(u1.username == person)
        .where(u1.username != u2.username)
        .group_by(u2.username)
        .order_by(func.count().desc())
    )

    results = session.execute(query).fetchall()

    for username, fic in results:
        print(f"{username} ({fic})")
